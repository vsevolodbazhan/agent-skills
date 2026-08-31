#!/usr/bin/env bash
set -euo pipefail

review_timeout="${CROSS_REVIEW_TIMEOUT_SECONDS:-1200}"
summary_timeout="${CROSS_SUMMARY_TIMEOUT_SECONDS:-600}"
terra_model="${CODEX_TERRA_MODEL:-gpt-5.6-terra}"
opus_model="${CLAUDE_OPUS_MODEL:-opus-4.8}"
luna_model="${CODEX_LUNA_MODEL:-gpt-5.6-luna}"

usage() {
    cat <<'EOF'
Usage:
  cross-code-review.sh current [options]
  cross-code-review.sh branch <ref> [options]
  cross-code-review.sh pr <number-or-url> [options]

Options:
  --base <ref>             Compare to this base ref.
  --allow-external-code    Confirm code may be sent to OpenAI and Anthropic.
  --allow-large            Allow more than 500 files or 20,000 changed lines.
  --no-artifacts           Do not retain reports under .cross-review/.
  --debug                  Retain temporary files and worktrees.
EOF
}

fail() { printf 'cross-code-review: %s\n' "$*" >&2; exit 1; }
require() { command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"; }

target_kind="${1:-}"
case "$target_kind" in
    current) shift ;;
    branch|pr) target_value="${2:-}"; [ -n "$target_value" ] || { usage >&2; exit 2; }; shift 2 ;;
    -h|--help|"") usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

base_override=""
allow_external=0
allow_large=0
keep_artifacts=1
debug=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --base) base_override="${2:-}"; [ -n "$base_override" ] || fail "--base needs a ref"; shift 2 ;;
        --allow-external-code) allow_external=1; shift ;;
        --allow-large) allow_large=1; shift ;;
        --no-artifacts) keep_artifacts=0; shift ;;
        --debug) debug=1; shift ;;
        *) fail "unknown option: $1" ;;
    esac
done

[ "$allow_external" = 1 ] || [ "${CROSS_CODE_REVIEW_ALLOW_EXTERNAL_CODE:-}" = 1 ] || \
    fail "pass --allow-external-code to confirm that code may be sent to OpenAI and Anthropic"
require git; require codex; require claude; require perl

root="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "run this inside a Git repository"
cd "$root"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/cross-code-review.XXXXXX")"
snapshot_dir="$root"
temporary_worktree=0

cleanup() {
    if [ "$temporary_worktree" = 1 ] && [ "$debug" = 0 ]; then
        git worktree remove --force "$snapshot_dir" >/dev/null 2>&1 || true
    fi
    [ "$debug" = 1 ] || rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

default_base_ref() {
    local remote_ref branch
    remote_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [ -n "$remote_ref" ]; then printf '%s\n' "$remote_ref"; return; fi
    require gh
    branch="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')" || fail "cannot determine the default branch"
    printf 'origin/%s\n' "$branch"
}

resolve_commit() {
    local ref="$1"
    git rev-parse --verify "${ref}^{commit}" 2>/dev/null || {
        git fetch --no-tags origin "$ref" >&2 || fail "cannot fetch $ref"
        git rev-parse --verify "${ref}^{commit}" 2>/dev/null || fail "cannot resolve $ref"
    }
}

if [ "$target_kind" = current ]; then
    head_commit="$(git rev-parse HEAD)"
    base_ref="${base_override:-$(default_base_ref)}"
    base_commit="$(resolve_commit "$base_ref")"
elif [ "$target_kind" = branch ]; then
    head_commit="$(resolve_commit "$target_value")"
    base_ref="${base_override:-$(default_base_ref)}"
    base_commit="$(resolve_commit "$base_ref")"
else
    require gh
    pr_number="$(printf '%s' "$target_value" | sed -E 's#.*(/pull/|/pulls/)##; s#/.*##')"
    case "$pr_number" in *[!0-9]*|"") fail "PR must be a number or a GitHub pull-request URL" ;; esac
    base_commit="$(gh pr view "$target_value" --json baseRefOid --jq '.baseRefOid')" || fail "cannot resolve PR base"
    git fetch --no-tags origin "$base_commit" >&2 || fail "cannot fetch PR base"
    git fetch --no-tags origin "pull/${pr_number}/head:refs/cross-code-review/pr-${pr_number}" >&2 || fail "cannot fetch PR head"
    head_commit="$(git rev-parse "refs/cross-code-review/pr-${pr_number}^{commit}")"
fi

if [ "$target_kind" != current ]; then
    snapshot_dir="$tmp_dir/repository"
    git worktree add --detach "$snapshot_dir" "$head_commit" >/dev/null
    temporary_worktree=1
fi

build_diff() {
    local directory="$1" base="$2" output="$3" path status
    : > "$output"
    git -C "$directory" diff --binary "$base" >> "$output"
    while IFS= read -r -d '' path; do
        status=0
        git -C "$directory" diff --no-index --binary /dev/null "$directory/$path" >> "$output" || status=$?
        [ "$status" = 0 ] || [ "$status" = 1 ] || return "$status"
    done < <(git -C "$directory" ls-files --others --exclude-standard -z)
}

review_diff="$tmp_dir/review.diff"
build_diff "$snapshot_dir" "$base_commit" "$review_diff"
initial_diff="$tmp_dir/initial.diff"
cp "$review_diff" "$initial_diff"
changed_files="$(grep -c '^diff --git ' "$review_diff" || true)"
changed_lines="$(grep -E '^[+-][^+-]' "$review_diff" | wc -l | tr -d ' ')"
if [ "$allow_large" = 0 ] && { [ "$changed_files" -gt 500 ] || [ "$changed_lines" -gt 20000 ]; }; then
    fail "review has $changed_files files and $changed_lines changed lines; pass --allow-large to continue"
fi

run_dir="$tmp_dir/run"
mkdir -p "$run_dir"
if [ "$keep_artifacts" = 1 ]; then
    git check-ignore -q -- .cross-review/.probe || fail ".cross-review/ is not ignored; add it to ignore rules or use --no-artifacts"
    artifact_dir="$root/.cross-review/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$artifact_dir"
else
    artifact_dir="$run_dir"
fi

terra_report="$run_dir/terra.md"
opus_report="$run_dir/opus.md"
summary_report="$run_dir/summary.md"
review_prompt="Review the requested change independently. Repository: $snapshot_dir
Base commit: $base_commit
Head commit: $head_commit
Captured diff: $review_diff

Inspect the source and captured diff. Do not edit files, install dependencies, access the network, or publish anything. You may run existing read-only checks when useful. Report actionable correctness, regression, security, test, or maintainability findings only. Exclude style-only feedback. For every finding provide severity (critical, high, medium, low), confidence, file and line, evidence, and a proposed fix. If there are no findings, say exactly 'No findings.'"

run_terra() {
    perl -e 'alarm shift; exec @ARGV or die "exec failed: $!\n"' "$review_timeout" \
        codex exec --ephemeral --model "$terra_model" -c 'model_reasoning_effort="high"' \
        --sandbox read-only --ask-for-approval never -C "$snapshot_dir" --output-last-message "$terra_report" "$review_prompt"
}

run_opus() {
    cd "$snapshot_dir"
    perl -e 'alarm shift; exec @ARGV or die "exec failed: $!\n"' "$review_timeout" \
        claude --print --no-session-persistence --model "$opus_model" --effort high \
        --permission-mode plan --disallowedTools Edit,Write,NotebookEdit "$review_prompt" > "$opus_report"
}

set +e
run_terra > "$run_dir/terra.stdout" 2> "$run_dir/terra.stderr" & terra_pid=$!
run_opus > "$run_dir/opus.stdout" 2> "$run_dir/opus.stderr" & opus_pid=$!
wait "$terra_pid"; terra_status=$?
wait "$opus_pid"; opus_status=$?
set -e
[ -s "$terra_report" ] || cp "$run_dir/terra.stdout" "$terra_report"
[ -s "$opus_report" ] || cp "$run_dir/opus.stdout" "$opus_report"

build_diff "$snapshot_dir" "$base_commit" "$tmp_dir/final.diff"
stale=0
cmp -s "$initial_diff" "$tmp_dir/final.diff" || stale=1
if [ "$terra_status" -ne 0 ] && [ "$opus_status" -ne 0 ]; then fail "both reviewers failed; see $artifact_dir"; fi

summary_prompt="Reconcile two independent code-review reports. Do not perform a new review or invent findings.
Repository: $snapshot_dir
Base: $base_commit
Head: $head_commit
Captured diff: $review_diff
Terra report: $terra_report (exit status $terra_status)
Opus report: $opus_report (exit status $opus_status)

Return concise Markdown. Merge duplicate findings, preserve valid one-reviewer findings, label meaningful disagreement, and order findings by severity. Each finding needs severity, confidence, file and line, evidence, and fix. Put low severity or low confidence items under 'Consider'. State when the result is partial. If no actionable findings remain, say so."

set +e
perl -e 'alarm shift; exec @ARGV or die "exec failed: $!\n"' "$summary_timeout" \
    codex exec --ephemeral --model "$luna_model" -c 'model_reasoning_effort="medium"' \
    --sandbox read-only --ask-for-approval never -C "$snapshot_dir" --output-last-message "$summary_report" "$summary_prompt" \
    > "$run_dir/luna.stdout" 2> "$run_dir/luna.stderr"
summary_status=$?
set -e
[ -s "$summary_report" ] || cp "$run_dir/luna.stdout" "$summary_report"
[ "$summary_status" -eq 0 ] || fail "Luna synthesis failed; see $artifact_dir"

if [ "$keep_artifacts" = 1 ]; then
    cp "$review_diff" "$artifact_dir/review.diff"
    cp "$terra_report" "$artifact_dir/terra.md"
    cp "$opus_report" "$artifact_dir/opus.md"
    cp "$summary_report" "$artifact_dir/summary.md"
    cp "$run_dir"/*.stderr "$artifact_dir/" 2>/dev/null || true
fi
cat "$summary_report"
if [ "$stale" = 1 ]; then
    printf '\nResult is stale: the reviewed state changed while the agents were running.\n' >&2
    exit 3
fi
if [ "$terra_status" -ne 0 ] || [ "$opus_status" -ne 0 ]; then
    printf '\nResult is partial: one reviewer failed.\n' >&2
fi
