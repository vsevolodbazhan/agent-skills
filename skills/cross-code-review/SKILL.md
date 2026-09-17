---
name: cross-code-review
description: Request code review from other model and/or harness.
---

# General

- If you are a Anthropic model, prioritize requesting review from OpenAI (Codex) models.
- If you are an OpenAI model, prioritize requesting review from Anthropic (Claude) models.
- Base branch is generally `master` but might be `main`.
- If you are given a PR to review, checkout its branch locally first.

# Codex

```
codex --model gpt-6-astra --sandbox read-only review --base main
```

# Claude

claude --permission-mode auto --model opus --print "Review current changes against the base branch `main`".
