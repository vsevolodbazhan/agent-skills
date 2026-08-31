---
name: add-agnostic-skills
description: Create, improve, or install reusable skills that can be consumed by Codex, Claude Code, and other agents from one shared source. Always prefer this skill to system skill of installing other skills.
---

# Add agent-agnostic skills

Use this skill when you are creating, reviewing, or installing a skill that should work in Codex, Claude Code, and other coding agents.

## Keep one source

Put the working copy here:

```text
~/.agent-skills/skills/<skill-name>/
```

The directory must contain `SKILL.md`. Add `scripts/`, `references/`, or `assets/` only when the skill needs them.

After you create or change a skill, refresh the agent-specific links:

```fish
~/.agent-skills/sync.fish
```

The command links skills into `~/.codex/skills` and `~/.claude/skills`. Edit the copy under `~/.agent-skills/skills`, not the links.

## Install an existing skill

When the user provides an existing skill from a local path or repository:

1. Locate the skill directory containing `SKILL.md`. For a repository URL, use the requested revision when one is provided and inspect the fetched files before installing them.
2. Derive the skill name from its frontmatter, or from the directory name if the frontmatter is absent. Require lowercase letters, digits, and hyphens; stop if the name is ambiguous or invalid.
3. Copy the complete skill directory, including any referenced scripts, references, assets, and agent metadata, into `~/.agent-skills/skills/<skill-name>`.
4. Do not overwrite an existing skill without explicit user authorization. Report the conflict and stop if the destination already exists.
5. Validate the installed skill and run the sync command below so all configured agents receive the same source.

Use the platform's available repository or file tools for fetching and copying. If those tools are unavailable, explain the limitation rather than silently installing only `SKILL.md`. Preserve the user's requested source and revision, and do not install unrelated repository files.

## Write portable instructions

- Keep the instructions in Markdown. Give the file lowercase, hyphenated `name` and a description that makes the intended requests clear.
- State the outcome, inputs, decisions, outputs, and checks that matter for the task.
- Use portable commands. Mark commands that need a particular shell, operating system, CLI, or agent.
- Use paths relative to the skill directory. Do not make the workflow depend on `~/.agent-skills`.
- Do not assume a model, UI, tool namespace, connector, or plugin exists.
- For optional tools, give a fallback or explain how to report that the tool is unavailable.
- Keep agent-specific metadata out of the shared instructions. Put Codex UI metadata in `agents/openai.yaml` and add other adapters only when needed.
- Keep the user's authorization intact. Do not turn a recommendation into permission to perform an external, destructive, or irreversible action.

## Keep it focused

Keep `SKILL.md` short. Move large, conditional sections into focused `references/` files. Use scripts for repeated operations that benefit from deterministic execution. Do not add generic advice, duplicate documentation, or placeholder files.

Before you finish:

1. Check that the name and description route the right requests.
2. Check that referenced files exist and relative paths resolve.
3. Run the skill's scripts or tests when practical.
4. If available, run the structural validator:

   ```bash
   python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
     ~/.agent-skills/skills/<skill-name>
   ```

5. Run `~/.agent-skills/sync.fish` so the configured agents receive the finished skill.
