# AI Skills

A collection of reusable AI skills for Claude, designed to be plugged into various projects and tasks. Each skill is a self-contained folder with its own style guide, requirements, and reference material.

## Skill Organization

Skills use two structural patterns depending on their nature:

**Single file (`SKILL.md` only)** — for skills where all content is always relevant together. If someone triggers the skill, they need the whole thing. Commands that reference each other, workflows that build on one another, style guides that apply as a unit. Examples: `adt`, `plsql-format`, `data-model`, `apex-qa`, `apex-rest`.

**Dedicated folder with references** — for skills that are situational and have their own sub-variants. The main `SKILL.md` stays lean and routes to the appropriate reference file based on context (e.g., platform, component). This avoids loading 200 lines of Mac-specific install steps when the user is on Windows. Examples: `adt-install` (Mac/Windows references), `adt-update` (oracledb/SQLcl/Instant Client references), `deployment`.

Rule of thumb: if content is always needed together, keep it in one file. If it's situational and has sub-variants, give it a folder with references.

## Repository Structure

```
skills/
  <skill-name>/
    SKILL.md              -- Core skill definition (required)
    references/           -- Optional: context-specific guides loaded on demand
    REQUIREMENTS.md       -- Optional: behavioral instructions for Claude
    ANALYSIS.md           -- Optional: reference analysis or real-world examples
```

## Available Skills

| Skill | Type | Description |
|---|---|---|
| [adt](skills/adt/) | Single file | ADT CLI commands: export_db, export_apex, export_data, patch, config, and developer workflow |
| [adt-setup](skills/adt-setup/) | Folder | ADT installation, project repo init, database connections, and dependency updates (Mac/Windows) |
| [apex-qa](skills/apex-qa/) | Single file | APEX application quality assurance, page design, component naming, MVC |
| [apex-rest](skills/apex-rest/) | Single file | APEX RESTful data services, ORDS modules, REST handlers |
| [data-model](skills/data-model/) | Single file | Oracle data model design: tables, columns, constraints, indexes |
| [deployment](skills/deployment/) | Folder | Deployment process and standards |
| [plsql-code-quality](skills/plsql-code-quality/) | Single file | PL/SQL code quality checks |
| [plsql-format](skills/plsql-format/) | Single file | PL/SQL formatting and style guide |
| [sql-formatter](skills/sql-formatter/) | Single file | SQL statement formatting |

## Adding a New Skill

1. Create a folder under `skills/` with a descriptive kebab-case name.
2. Add a `SKILL.md` with the core rules, patterns, and examples.
3. If the skill has sub-variants (platforms, components), add a `references/` folder with separate files for each variant and route to them from `SKILL.md`.
4. Update this table with the new skill.
