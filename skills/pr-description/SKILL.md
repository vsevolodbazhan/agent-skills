---
name: pr-description
description: Write a pull request description.
---

# General

- Use `gh` CLI if available. 
- Attach screenshots and other media if applicable.
- Produce a PR body that a reviewer can read in under a minute and know what to look at.
- Bullet points by default. Prose only when a bullet would mangle the meaning, and then at most two sentences.
- No bullet point restates another.
- If you're unsure you can write an accurate description, ask the user for details.
- Use English conventional commit PR titles and Russian PR descriptions.
- The problem is readable by someone who has not seen the diff.
- Every optional section present earns its place.

## Structure

- Use only these sections, in this order (unless explicitly asked otherwise).
- When writing a PR description in Russian use Russian headings.
- Don't add Checks/Проверки section.

```markdown
## Problem/Проблема
- What led to the changes in the PR, what was broken or did not work as expected, what was missing.

## Context/Контекст
- Optional. Additional information that would help the reviewer understand the problem better and whether the changes indeed address this problem. Might include links to Jira tickets, Slack threads, other PRs and issues, relevant documentation.

## Changes/Изменения
- The change, in reviewer-relevant terms. Don't retell what is already in the diff; provide a high-level overview.
- If the changes span multiple different files, specify the purpose of modules and relationships between them.

## Limitations/Ограничения
- Optional. Known gaps, deliberate omissions, alternatives considered, and why not.

## Examples/Примеры
- Optional. Before/after, sample output, commands, screenshots. Don't put tests or checks here. This section applies to PRs where the changes can be demoed.
```
