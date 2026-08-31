---
name: cross-code-review
description: Review current-branch, named-branch, or GitHub PR changes independently with Codex and Claude, then return a reconciled report.
disable-model-invocation: true
---

# Cross-code review

Run `scripts/cross-code-review.sh` from the repository to review. It launches Codex Terra and Claude Opus in parallel, then asks Codex Luna to reconcile their reports.

## Inputs

Use one target:

```bash
bash <skill-dir>/scripts/cross-code-review.sh current --allow-external-code
bash <skill-dir>/scripts/cross-code-review.sh branch feature/login --allow-external-code
bash <skill-dir>/scripts/cross-code-review.sh pr 123 --allow-external-code
```

`pr` accepts a GitHub PR number or URL and needs `gh`. Add `--base <ref>` for a non-default comparison base, `--allow-large` for more than 500 files or 20,000 changed lines, and `--no-artifacts` to discard the reports after printing them.

The script sends the selected code and diff to OpenAI and Anthropic. Ask for confirmation before use unless the caller supplied `--allow-external-code` or set `CROSS_CODE_REVIEW_ALLOW_EXTERNAL_CODE=1`.

## Behavior

- The reviewers share one checkout and receive the same base, head, and captured diff. Named branches and PRs use one temporary Git worktree so the caller's checkout remains untouched.
- Codex Terra and Claude Opus review independently. They report actionable findings only, with severity, confidence, file and line, evidence, and a suggested fix.
- Luna receives the target, diff, and both reports. It merges duplicates, keeps well-supported single-reviewer findings, labels disagreement, and does not invent findings.
- The script marks the result stale and exits nonzero if the reviewed state changes before completion. A single reviewer failure produces a partial report. Both failing prevents synthesis.

Reports are retained in `.cross-review/<timestamp>/` by default. Add `.cross-review/` to the reviewed repository's ignore rules before use. The skill will not change its `.gitignore` for you.

## Checks

Before running, confirm `git`, `codex`, `claude`, and `perl` are available. Confirm `gh` for a PR. The script uses the requested defaults: Terra and Opus with high effort, Luna with medium effort. Environment variables can override model names and timeouts:

```text
CODEX_TERRA_MODEL  CLAUDE_OPUS_MODEL  CODEX_LUNA_MODEL
CROSS_REVIEW_TIMEOUT_SECONDS  CROSS_SUMMARY_TIMEOUT_SECONDS
```
