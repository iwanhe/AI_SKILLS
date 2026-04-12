#!/bin/bash
#
# Create symbolic links from ~/.claude/skills/ to AI_SKILLS skills folder.
# This makes all custom skills available across all Claude projects.
#
# Usage: bash ~/Dropbox/PROJECTS/AI_SKILLS/setup_global_skills.sh
#

SKILLS_SRC="$HOME/Library/CloudStorage/Dropbox/PROJECTS/AI_SKILLS/skills"
SKILLS_DST="$HOME/.claude/skills"

mkdir -p "$SKILLS_DST"

# Remove stale symlinks (pointing to deleted or moved skill folders)
for link in "$SKILLS_DST"/*/; do
    link="${link%/}"
    if [ -L "$link" ] && [ ! -e "$link" ]; then
        echo "  removed stale: $(basename "$link")"
        rm "$link"
    fi
done

# Create symlinks for current skills
for skill_dir in "$SKILLS_SRC"/*/; do
    skill_name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
        if [ -L "$SKILLS_DST/$skill_name" ]; then
            echo "  skip: $skill_name (symlink already exists)"
        elif [ -e "$SKILLS_DST/$skill_name" ]; then
            echo "  skip: $skill_name (file/folder already exists, not overwriting)"
        else
            ln -s "$skill_dir" "$SKILLS_DST/$skill_name"
            echo "  linked: $skill_name"
        fi
    fi
done

echo ""
echo "Done. Skills in ~/.claude/skills/:"
ls -la "$SKILLS_DST"
