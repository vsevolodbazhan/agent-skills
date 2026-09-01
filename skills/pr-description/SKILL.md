---
name: pr-description
description: Write or rewrite a pull request description in the fixed Problem / Context / Changes / Limitations / Examples structure. Use whenever a PR body is being drafted, opened, edited, or reviewed for clarity — including "open a PR", "write the PR description", "fill in the PR body", "оформи PR", "напиши описание PR" — and before calling any tool that creates or updates a PR. Also use when a PR body exists but is unstructured, prose-heavy, or just a diff summary.
---

# PR description

Produce a PR body that a reviewer can read in under a minute and know what to
look at.

## Ask when you do not know

The diff shows what changed. It does not show why, who asked, what was ruled
out, or what still does not work. Those come from the user.

**Never invent them.** When a required section cannot be written from the diff,
the commits, the linked ticket, or the conversation so far — stop and ask.
A short question costs less than a confident, wrong Problem statement that a
reviewer has to unpick.

Ask when you cannot answer:

- **Problem** — why does this change need to exist? What breaks or stays broken
  without it?
- **Context** — is there a ticket, incident, Slack thread, or review comment
  behind this? (Skip the section if the user says there is none.)
- **Limitations** — was anything knowingly left out, or another approach
  rejected?

How to ask:

- Batch every open question into one message. Do not drip-feed them.
- Show the draft you already have, with the unknown parts marked, so the user
  answers in context.
- Offer your best guess and ask for confirmation when you have one
  ("reads like this fixes the timeout in the nightly sync — correct?"). A
  guess offered for confirmation is fine; a guess written silently into the PR
  is not.
- If the user declines to answer, leave the optional section out and say
  plainly which part of the description is thin, rather than padding it.

## Structure

Use these sections, in this order, with these exact headings:

```markdown
## Problem
- What is broken, missing, or costly today.

## Context
- Optional. Why this surfaced now; prior attempts; links with a one-line gist.

## Changes
- The change, in reviewer-relevant terms.

## Limitations
- Optional. Known gaps, deliberate omissions, alternatives considered and why not.

## Examples
- Optional. Before/after, sample output, commands, screenshots.
```

- **Problem** and **Changes** are always present.
- The other three appear only when they carry information. Never emit an empty
  or filler section.
- Nothing above the first heading — no summary paragraph, no restated title.

## Rules

- Bullets by default. Prose only when a bullet would mangle the meaning, and
  then at most two sentences.
- One fact per bullet. No bullet longer than two lines.
- Whole body under ~200 words for a normal PR. If it runs longer, the PR is
  probably too big — say so to the user rather than padding the description.
- Problem describes the situation, not the patch. If a bullet under Problem
  names a function you added, it belongs under Changes.
- Changes describes behaviour and intent, not a file-by-file diff walkthrough.
  The diff is already in the PR.
- Link issues/tickets with the gist inline (`Fixes DF-123 — nightly sync drops
  late rows`), not a bare URL or bare ID.
- No marketing adjectives, no "this PR ...", no restating the title, no
  self-congratulation, no emoji headers.
- Match the repository's language: if existing PRs and commits are in Russian,
  write in Russian and translate the headings accordingly.

## Workflow

1. **Gather.** Read the diff (`git diff <base>...HEAD`, `git log <base>..HEAD`)
   and the linked ticket or issue if there is one. If the branch's base is
   unclear, ask rather than guessing.
2. **Find the problem.** Ask: what would break, stay broken, or stay annoying
   if this PR were closed unmerged? That answer is the Problem section. If the
   diff and the ticket do not tell you, ask the user — see "Ask when you do not
   know" above.
3. **Check repo conventions.** If the repo has `.github/PULL_REQUEST_TEMPLATE.md`
   or `CONTRIBUTING.md`, the repo's template wins. Keep its required sections
   and checkboxes, and apply this skill's brevity and bullet rules inside them.
   Add the sections above only where they do not conflict.
4. **Ask about the gaps.** Before drafting, collect everything you could not
   determine and put it to the user in one message.
5. **Draft** using the structure and rules above.
6. **Cut.** Delete every bullet that a reviewer looking at the diff already
   knows. Merge near-duplicate bullets.
7. **Confirm before publishing.** Show the body in chat first. Creating or
   editing a PR is an external, visible action — do it only after the user
   says yes, and only with the tool or CLI the user already uses in that repo.

## Checks before you hand it over

- Problem is readable by someone who has not seen the diff.
- Every optional section present earns its place.
- No bullet restates another.
- No claim about test results or behaviour you did not verify.
- No motivation, ticket, or rationale you inferred but never confirmed.
