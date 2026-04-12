---
name: adt
description: "APEX Deployment Tool (ADT) — CLI tool for Oracle APEX and database CI/CD automation. Use this skill whenever the user needs to export database objects, export APEX applications, export data, create or deploy patches, recompile invalid objects, or manage Oracle APEX deployment workflows. Triggers: adt, apex deployment, export database, export apex, export data, create patch, deploy patch, apex ci/cd, database export, patch creation, installation script, deployment order, recompile, invalid objects, compile, broken packages, native compilation, PLSQL_OPTIMIZE_LEVEL."
---

# ADT (APEX Deployment Tool)

ADT is a Python-based CLI tool that automates the export, patching, and deployment of Oracle Database objects and APEX applications. It reads from Git, config files, and the database — it never stores metadata in the database itself.

ADT is invoked via a shell alias: `adt {command} {arguments}`.


## Core Commands


### adt export_db

Export database objects into the repository folder structure. Each object becomes a clean `.sql` file organized by type. Filters by time (`-recent`), object type (`-type`), and object name (`-name`) can be combined.

For full details on flags, output structure, cleanup behavior, and edge cases, read `references/export-db.md`.

**Quick reference:**

```bash
adt export_db -recent 7                                    # objects changed in last 7 days
adt export_db -type PACKAGE% VIEW%                         # specific object types
adt export_db -name APP_% -recent 7                        # combine name + time filters
adt export_db -type JOB                                    # jobs (no -recent — jobs lack timestamp)
adt export_db -recent 7 -delete                            # clean export (delete folders first)
```

**Critical:** JOB objects have no `last_ddl_time` — never combine `-type JOB` with `-recent`. Export jobs separately without the `-recent` flag.

**Rule:** Always show the user the full console output from this command (overview table, deleted objects, export progress).


### adt export_apex

Export APEX applications, components, REST services, and workspace files. Supports multiple export formats, scoping by app/workspace/group, and filtering by recent changes or developer.

For full details on flags, formats, workflows, and troubleshooting, read `references/export-apex.md`.

**Quick reference:**

```bash
adt export_apex -app 100 -only -full -split -files -rest -readable -recent 0   # typical export
adt export_apex -app 100 200 -only -split -readable -recent 3                  # multiple apps, recent changes
adt export_apex -reveal                                                         # list available apps
adt export_apex -reveal -schema APPS                                            # list apps for a different schema
```

**Rules:**
- Always pass `-only` to override config defaults — explicitly control which formats are exported.
- Always pass `-recent 0` unless the user asks to see recently changed components. Note: `-recent` only controls whether a list of changes is shown — the export itself always exports all components.
- Typical formats: `-full -split -files -files_ws -rest -readable`. Skip `-embedded` unless explicitly asked (it slows exports).
- If apps don't show up, the schema in `connections.yaml` likely doesn't match the app owner — try `-schema`.

**Rule:** Always show the user the full console output from this command.


### adt export_data

Export table data (seed data, LOV tables, configuration) into CSV files with auto-generated SQL MERGE statements. Designed for reference data, not sensitive or transactional data.

For full details on flags, output format, limitations, and NLS considerations, read `references/export-data.md`.

**Quick reference:**

```bash
adt export_data -name CONFIG_PARAMETERS LOV_STATUS        # specific tables
adt export_data -name CONFIG% LOV_%                        # wildcard patterns
adt export_data                                            # re-export all previously exported tables
```

**Limitations:** BLOB, CLOB, XMLTYPE, JSON columns are not exported. Audit columns (CREATED_BY, CREATED_AT, etc.) are skipped per config. Set correct NLS date formats on target environments before running the generated `.sql` files.

**Rule:** Always show the user the full console output from this command.


### adt patch

Create and deploy patch files from Git commits. The most powerful ADT command — reads commits, resolves dependencies, orders objects, and generates deployment scripts.

For full details on all flags, patch templates/scripts, object ordering, output structure, and known limitations, read `references/patch.md`.

**Quick reference:**

```bash
adt patch -target UAT -patch TASK_ID                          # preview matching commits
adt patch -target UAT -patch TASK_ID -create                  # create the patch
adt patch -target UAT -patch TASK_ID -create -deploy          # create and deploy
adt patch -target UAT -patch TASK_ID -deploy -force           # force redeploy
adt patch -target UAT -commits 50 -my                         # browse my recent commits
adt patch -target UAT -patch TASK_ID -commit 1-20 -ignore 5   # cherry-pick commits
adt patch -target UAT -patch TASK_ID -head                    # use HEAD file versions
adt patch -target UAT -patch TASK_ID -local                   # use local (uncommitted) files
adt patch -target UAT -patch TASK_ID -create -full            # full APEX export in patch
```

**Key concepts:**
- Commit filtering: `-commit`, `-ignore` (support ranges like `1-20`), `-search`, `-my`, `-by`
- File sources: default (from matching commit), `-head` (latest commit), `-local` (working tree)
- Templates (`config/patch_template/`) apply to every patch; scripts (`config/patch_scripts/{CARD}/`) apply to one patch
- Object ordering follows `patch_map` in `config.yaml`: Sequences → Tables → Types → … → Jobs


## Other Core Commands


### adt recompile

Recompile invalid database objects. Supports forced recompilation with PL/SQL compilation flags (native/interpreted, optimization level, PL/Scope, warnings). Handles dependency-aware retry logic automatically.

For full details on flags, behavior, and use cases, read `references/recompile.md`.

**Quick reference:**

```bash
adt recompile -target DEV                                  # recompile invalid objects
adt recompile -target DEV -force -native -level 3          # force recompile all with native + optimization
adt recompile -target DEV -type PACKAGE% -name XX%         # scope by type and name
```


## Other Useful Commands

| Command | Purpose |
|---|---|
| `adt search_apex` | Search for objects within APEX by page, type, or name |
| `adt search_repo` | Search Git history by commit, author, files, or branch |
| `adt live_upload` | Upload files directly to APEX (live update during development) |
| `adt deploy` | Deploy patches to environments |
| `adt move` | Move or rename database objects |


## Typical Developer Workflow with ADT

1. Pick up a task, create a feature branch from `main`.
2. Make changes in the DEV database and APEX builder.
3. Export changes:
   - `adt export_db -recent 1` (database objects changed today)
   - `adt export_apex -split -readable -embedded -recent 1` (APEX changes)
   - `adt export_data -name TABLE_NAME` (if data changed)
4. Stage and commit exported files with the task ID prefix.
5. When the task is complete, generate the patch:
   - `adt patch -patch TASK-123 -create`
6. Commit the patch folder.
7. Create a pull request.
