#!/usr/bin/env fish

set -l base_dir "$AGENT_SKILLS_DIR"

if test -z "$base_dir"
    set base_dir "$HOME/.agent-skills"
end

set -l source_dir "$base_dir/skills"
set -l targets \
    "$HOME/.codex/skills" \
    "$HOME/.claude/skills"

mkdir -p "$source_dir"

for target in $targets
    mkdir -p "$target"

    for skill_path in "$source_dir"/*
        if not test -d "$skill_path"
            continue
        end

        set -l skill_name (basename "$skill_path")
        set -l skill_file "$skill_path/SKILL.md"
        set -l destination "$target/$skill_name"

        if not test -f "$skill_file"
            echo "Skipping $skill_name: missing SKILL.md" >&2
            continue
        end

        # Never replace a real file or directory.
        if test -e "$destination"; and not test -L "$destination"
            echo "Skipping $destination: real file or directory exists" >&2
            continue
        end

        # Refresh an existing symlink.
        if test -L "$destination"
            rm "$destination"
        end

        ln -s "$skill_path" "$destination"
        echo "Linked $skill_name -> $target"
    end
end
