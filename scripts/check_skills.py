#!/usr/bin/env python3
"""Validate every skill directory in this repository."""

import re
import sys
from pathlib import Path

import yaml


MAX_SKILL_NAME_LENGTH = 64
ALLOWED_PROPERTIES = {"name", "description", "license", "allowed-tools", "metadata"}


def validate_skill(skill_path: Path) -> tuple[bool, str]:
    skill_file = skill_path / "SKILL.md"
    if not skill_file.exists():
        return False, "SKILL.md not found"

    content = skill_file.read_text()
    if not content.startswith("---"):
        return False, "No YAML frontmatter found"

    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    try:
        frontmatter = yaml.safe_load(match.group(1))
    except yaml.YAMLError as error:
        return False, f"Invalid YAML in frontmatter: {error}"

    if not isinstance(frontmatter, dict):
        return False, "Frontmatter must be a YAML dictionary"

    unexpected = set(frontmatter) - ALLOWED_PROPERTIES
    if unexpected:
        names = ", ".join(sorted(unexpected))
        allowed = ", ".join(sorted(ALLOWED_PROPERTIES))
        return False, f"Unexpected key(s): {names}. Allowed properties are: {allowed}"

    for required in ("name", "description"):
        if required not in frontmatter:
            return False, f"Missing '{required}' in frontmatter"

    name = frontmatter["name"]
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if not re.fullmatch(r"[a-z0-9-]+", name):
        return False, "Name should use lowercase letters, digits, and hyphens only"
    if name.startswith("-") or name.endswith("-") or "--" in name:
        return False, "Name cannot start or end with a hyphen or contain consecutive hyphens"
    if len(name) > MAX_SKILL_NAME_LENGTH:
        return False, f"Name is too long ({len(name)} characters)"

    description = frontmatter["description"]
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description.startswith("[TODO:"):
        return False, "Description contains an unfinished TODO placeholder"
    if "<" in description or ">" in description:
        return False, "Description cannot contain angle brackets (< or >)"
    if len(description) > 1024:
        return False, f"Description is too long ({len(description)} characters)"

    body = content[match.end() :]
    fence_marker = None
    fence_length = 0
    for line in body.splitlines():
        fence = re.match(r"^[ \t]*(?:(?:[-+*]|\d+[.)])[ \t]+)?(`{3,}|~{3,})(.*)$", line)
        if fence:
            marker = fence.group(1)
            if fence_marker is None:
                fence_marker = marker[0]
                fence_length = len(marker)
            elif marker[0] == fence_marker and len(marker) >= fence_length and not fence.group(2).strip():
                fence_marker = None
                fence_length = 0
            continue

        if fence_marker is None and re.fullmatch(r"[ ]{0,3}\[TODO:[^\n]*\][ \t]*", line):
            return False, "Skill instructions contain an unfinished TODO placeholder"

    return True, "valid"


def main() -> int:
    skills_dir = Path(__file__).resolve().parent.parent / "skills"
    skill_paths = sorted(path for path in skills_dir.iterdir() if path.is_dir())
    failures = 0

    for skill_path in skill_paths:
        valid, message = validate_skill(skill_path)
        status = "PASS" if valid else "FAIL"
        print(f"{status}: {skill_path.name} ({message})")
        failures += not valid

    if failures:
        print(f"{failures} skill(s) failed validation.", file=sys.stderr)
        return 1

    print(f"Checked {len(skill_paths)} skill(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
