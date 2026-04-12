---
name: adt
description: "APEX Deployment Tool (ADT) — CLI tool for Oracle APEX and database CI/CD automation. Use this skill whenever the user needs to export database objects, export APEX applications, export data, create or deploy patches, recompile invalid objects, search APEX components, search Git history, or manage Oracle APEX deployment workflows. Triggers: adt, apex deployment, export database, export apex, export data, create patch, deploy patch, apex ci/cd, database export, patch creation, installation script, deployment order, recompile, invalid objects, compile, broken packages, native compilation, PLSQL_OPTIMIZE_LEVEL, search apex, search repo, find object, object references, restore file, git history, live upload, static files, upload css, upload js, minify."
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


### adt search_apex

Search for database objects referenced by APEX applications. Parses the Embedded Code report to find which packages, views, tables, etc. are used on which pages and shared components. Requires `-embedded` export first.

For full details on flags, output format, patch integration, and tips, read `references/search-apex.md`.

**Quick reference:**

```bash
adt search_apex -app 100                                     # all referenced objects in app
adt search_apex -app 100 -page 1 10                          # objects on specific pages
adt search_apex -app 100 -name APP_% -type PACKAGE           # filter by name and type
adt search_apex -app 100 -schema HR                          # precise matching via schema prefix
adt search_apex -app 100 -patch TASK-123                     # copy refs to patch_scripts folder
```

**Prerequisite:** run `adt export_apex -app {ID} -only -embedded` first to generate the embedded code report.


### adt search_repo

Search Git commit history for database objects — by commit message, file name, object type, object name, author, or date range. Also supports restoring previous file versions.

For full details on flags, restore behavior, and tips, read `references/search-repo.md`.

**Quick reference:**

```bash
adt search_repo -summary TASK-123                            # find commits by message
adt search_repo -file MY_PACKAGE                             # find file (even deleted ones)
adt search_repo -type VIEW -recent 30                        # view changes in last 30 days
adt search_repo -name APP_CORE% -my                          # my changes to matching objects
adt search_repo -file MY_PACKAGE -restore                    # restore historical versions
adt search_repo -file MY_PACKAGE -restore -stage             # restore as staged git commits
```

**Prerequisite:** commit index must exist — run `adt patch -target {ENV} -rebuild` if missing.


### adt live_upload

Monitor a local folder and automatically upload changed JS, CSS, and other static files to APEX. Includes automatic minification. Runs in a continuous loop until Ctrl+C.

For full details on flags, minification, monitored directories, and tips, read `references/live-upload.md`.

**Quick reference:**

```bash
adt live_upload                                              # monitor with defaults from config
adt live_upload -app 100                                     # monitor a specific app's files
adt live_upload -app 100 -folder ./my_static/                # custom folder
adt live_upload -workspace                                   # workspace files instead of app files
adt live_upload -show                                        # list monitored files at startup
```


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
