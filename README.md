# AI Skills

A collection of reusable AI skills for Claude, designed to be plugged into various projects and tasks. Each skill is a self-contained folder with its own style guide, requirements, and reference material.

## Skill Organization

Skills use two structural patterns depending on their nature:

**Single file (`SKILL.md` only)** — for skills where all content is always relevant together. If someone triggers the skill, they need the whole thing. Style guides that apply as a unit, compact command references. Examples: `plsql-format`, `data-model`, `apex-qa`, `apex-rest`.

**Folder with references** — for skills that are situational or cover multiple sub-topics. The main `SKILL.md` stays lean (quick reference + key concepts) and routes to the appropriate reference file based on context. This avoids loading 200 lines of Mac-specific install steps when the user is on Windows, or the full patch flag table when the user just needs to export. Examples: `adt` (8 command references), `adt-setup` (platform + component references), `deployment`.

Rule of thumb: if content is always needed together, keep it in one file. If it's situational, has sub-variants, or exceeds ~150 lines, split into a folder with references.

## Repository Structure

```
skills/
  <skill-name>/
    SKILL.md              -- Core skill definition (required)
    references/           -- Optional: detailed guides loaded on demand
```

## Available Skills

### ADT (APEX Deployment Tool)

| Skill | References | Description |
|---|---|---|
| [adt](skills/adt/) | export-db, export-apex, export-data, patch, recompile, search-apex, search-repo, live-upload | ADT CLI commands, developer workflow, export/patch/search/deploy operations |
| [adt-setup](skills/adt-setup/) | install-mac, install-windows, init-repo, connections, update-oracledb, update-sqlcl, update-instant-client | Installation, project init, database connections, dependency updates |
| [deployment](skills/deployment/) | process | Deployment process and standards |

The `adt` and `adt-setup` skills are complementary. `adt` covers the day-to-day CLI commands (exporting, patching, searching), while `adt-setup` handles everything before that — installing ADT and its prerequisites on Mac or Windows, initializing a new project repo with config templates and `.gitignore` patterns (`init-repo`), creating database connections with wallet/thick/thin modes, and keeping dependencies like oracledb, SQLcl, and Instant Client up to date. The split keeps the daily-use skill lean and avoids loading install/setup content that's only needed once per machine or project.

### Oracle APEX & PL/SQL

| Skill | Type | Description |
|---|---|---|
| [apex-qa](skills/apex-qa/) | Single file | APEX application quality assurance, page design, component naming, MVC |
| [apex-rest](skills/apex-rest/) | Single file | APEX RESTful data services, ORDS modules, REST handlers |
| [data-model](skills/data-model/) | Single file | Oracle data model design: tables, columns, constraints, indexes |
| [plsql-format](skills/plsql-format/) | Single file | PL/SQL formatting and style guide |
| [plsql-code-quality](skills/plsql-code-quality/) | Single file | PL/SQL code quality checks and anti-patterns |
| [sql-formatter](skills/sql-formatter/) | Single file | SQL statement formatting |

## Adding a New Skill

1. Create a folder under `skills/` with a descriptive kebab-case name.
2. Add a `SKILL.md` with the core rules, patterns, and examples.
3. If the skill has sub-variants or exceeds ~150 lines, add a `references/` folder with separate files and route to them from `SKILL.md`.
4. Update this README with the new skill.
