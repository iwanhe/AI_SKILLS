# AI Skills

A collection of reusable AI skills for Claude, designed to be plugged into various projects and tasks. Each skill is a self-contained folder with its own style guide, requirements, and reference material.

## Repository Structure

```
skills/
  <skill-name>/
    SKILL.md          -- Core skill definition (style guide, rules, examples)
    REQUIREMENTS.md   -- Behavioral instructions for Claude when using this skill
    ANALYSIS.md       -- Optional: reference analysis or real-world examples
```

## Available Skills

| Skill | Description |
|---|---|
| [plsql-format](skills/plsql-format/) | PL/SQL code formatting and style guide for Oracle packages, procedures, functions, and SQL statements. Covers case conventions, indentation, alignment, comments, exception handling, and more. |

## Adding a New Skill

1. Create a folder under `skills/` with a descriptive kebab-case name.
2. Add a `SKILL.md` with the core rules, patterns, and examples.
3. Add a `REQUIREMENTS.md` describing how Claude should behave when the skill is active.
4. Optionally add an `ANALYSIS.md` or other reference files.
5. Update this table with the new skill.
