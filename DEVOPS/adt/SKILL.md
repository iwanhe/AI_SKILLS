---
created: 2026-04-16
updated: 2026-05-30
name: adt
description: "APEX Deployment Tool (ADT) — CLI tool for Oracle APEX and database CI/CD automation. Use this skill whenever the user needs to export database objects, export APEX applications, export data, create or deploy patches, recompile invalid objects, search APEX components, search Git history, or manage Oracle APEX deployment workflows. Triggers: adt, apex deployment, export database, export apex, export data, create patch, deploy patch, apex ci/cd, database export, patch creation, installation script, deployment order, recompile, invalid objects, compile, broken packages, native compilation, PLSQL_OPTIMIZE_LEVEL, search apex, search repo, find object, object references, restore file, git history, live upload, static files, upload css, upload js, minify."
---
# ADT (APEX Deployment Tool)

ADT is a Python-based CLI tool that automates the export, patching, and deployment of Oracle Database objects and APEX applications. It reads from Git, config files, and the database — it never stores metadata in the database itself. Source and docs: https://github.com/jkvetina/ADT.

ADT is invoked via a shell alias: `adt {command} {arguments}` (see the `adt-setup` skill for installation and shell alias setup).

ADT.ai is the Python rewrite under `/Users/dobby/Library/CloudStorage/Dropbox/PROJECTS/ADT.ai`. For ADT.ai setup, use `SETUP.md`, `USAGE.md`, and `adtai doctor`; do not create connection files automatically unless Jan explicitly approves that scope.

For ADT.ai `export_apex`, do not carry over old ADT's `-all`, `-only`, `-no...` format flags, or configured export-format defaults. ADT.ai exports only the positive format flags named on the command line: `-full`, `-split`, `-readable`, `-embedded`, `-rest`, `-files`, and `-files_ws`.

For ADT.ai `export_apex -reveal`, preserve old ADT console output shape: the connection/version block, `WORKSPACES:` heading, grouped `APEX APPLICATIONS: <group>` sections, compact application columns, old truncation, and timer are part of parity.

For ADT.ai `export_apex` exports, preserve old ADT progress output shape: print `APP <id>/<alias>, EXPORTING:` before format progress lines, use the old labels (`FULL APP EXPORT`, `SPLIT COMPONENTS`, etc.), make progress dots grow with completion percentage instead of filling the whole line at every refresh, and seed the ETA column from `config/apex_timers.yaml` previous-run averages until the final line shows elapsed time.

For ADT.ai `export_apex` action execution, bind only parameters that are present in the selected action SQL text. Readable and embedded exports do not accept every full/split export option; tests must catch extra unsupported binds such as `with_comments`.


## Stamp

On success, run: `python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SCRIPTS/skills_log.py stamp adt`

## Core Commands


### adt export_db

Export database objects into the repository folder structure. Each object becomes a clean `.sql` file organized by type. Filters by time (`-recent`), object type (`-type`), and object name (`-name`) can be combined.

For full details on flags, output structure, cleanup behavior, and edge cases, read `references/export-db.md`.

**Quick reference** – pick one line, run as its own bash call:

Objects changed in last 7 days:

```bash
adt export_db -recent 7
```

Specific object types:

```bash
adt export_db -type PACKAGE% VIEW%
```

Combine name + time filters:

```bash
adt export_db -name APP_% -recent 7
```

Jobs (no `-recent` – jobs lack timestamp):

```bash
adt export_db -type JOB
```

Clean export (delete folders first):

```bash
adt export_db -recent 7 -delete
```

**Critical:** JOB objects have no `last_ddl_time` — never combine `-type JOB` with `-recent`. Export jobs separately without the `-recent` flag.

**Rule:** Always show the user the full console output from this command (overview table, deleted objects, export progress).


### adt export_apex

Export APEX applications, components, REST services, and workspace files. Supports multiple export formats, scoping by app/workspace/group, and filtering by recent changes or developer.

For full details on flags, formats, workflows, and troubleshooting, read `references/export-apex.md`.

**Quick reference** – pick one line, run as its own bash call:

Typical export:

```bash
adt export_apex -app 100 -only -full -split -files -rest -readable -recent 0
```

Multiple apps, recent changes only in listing:

```bash
adt export_apex -app 100 200 -only -split -readable -recent 3
```

List available apps:

```bash
adt export_apex -reveal
```

List apps under a different schema:

```bash
adt export_apex -reveal -schema APPS
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

**Quick reference** – pick one line, run as its own bash call:

Specific tables:

```bash
adt export_data -name CONFIG_PARAMETERS LOV_STATUS
```

Wildcard patterns:

```bash
adt export_data -name CONFIG% LOV_%
```

Re-export all previously exported tables:

```bash
adt export_data
```

**Limitations:** BLOB, CLOB, XMLTYPE, JSON columns are not exported. Audit columns (CREATED_BY, CREATED_AT, etc.) are skipped per config. Set correct NLS date formats on target environments before running the generated `.sql` files.

**Rule:** Always show the user the full console output from this command.


### adt patch

Create and deploy patch files from Git commits. The most powerful ADT command — reads commits, resolves dependencies, orders objects, and generates deployment scripts.

For full details on all flags, patch templates/scripts, object ordering, output structure, and known limitations, read `references/patch.md`.

**Quick reference** – pick one line, run as its own bash call:

Preview matching commits:

```bash
adt patch -target UAT -patch TASK_ID
```

Create the patch:

```bash
adt patch -target UAT -patch TASK_ID -create
```

Create and deploy:

```bash
adt patch -target UAT -patch TASK_ID -create -deploy
```

Force redeploy:

```bash
adt patch -target UAT -patch TASK_ID -deploy -force
```

Browse my recent commits:

```bash
adt patch -target UAT -commits 50 -my
```

Cherry-pick commits (ranges supported, e.g. `1-20`):

```bash
adt patch -target UAT -patch TASK_ID -commit 1-20 -ignore 5
```

Use HEAD file versions:

```bash
adt patch -target UAT -patch TASK_ID -head
```

Use local (uncommitted) files:

```bash
adt patch -target UAT -patch TASK_ID -local
```

Full APEX export in patch:

```bash
adt patch -target UAT -patch TASK_ID -create -full
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

**Quick reference** – pick one line, run as its own bash call:

Recompile invalid objects:

```bash
adt recompile -target DEV
```

Force recompile all with native + optimization:

```bash
adt recompile -target DEV -force -native -level 3
```

Scope by type and name:

```bash
adt recompile -target DEV -type PACKAGE% -name XX%
```


### adt search_apex

Search for database objects referenced by APEX applications. Parses the Embedded Code report to find which packages, views, tables, etc. are used on which pages and shared components. Requires `-embedded` export first.

For full details on flags, output format, patch integration, and tips, read `references/search-apex.md`.

**Quick reference** – pick one line, run as its own bash call:

All referenced objects in app:

```bash
adt search_apex -app 100
```

Objects on specific pages:

```bash
adt search_apex -app 100 -page 1 10
```

Filter by name and type:

```bash
adt search_apex -app 100 -name APP_% -type PACKAGE
```

Precise matching via schema prefix:

```bash
adt search_apex -app 100 -schema HR
```

Copy refs to patch_scripts folder:

```bash
adt search_apex -app 100 -patch TASK-123
```

**Prerequisite:** run `adt export_apex -app {ID} -only -embedded` first to generate the embedded code report.


### adt search_repo

Search Git commit history for database objects — by commit message, file name, object type, object name, author, or date range. Also supports restoring previous file versions.

For full details on flags, restore behavior, and tips, read `references/search-repo.md`.

**Quick reference** – pick one line, run as its own bash call:

Find commits by message:

```bash
adt search_repo -summary TASK-123
```

Find file (even deleted ones):

```bash
adt search_repo -file MY_PACKAGE
```

View changes in last 30 days:

```bash
adt search_repo -type VIEW -recent 30
```

My changes to matching objects:

```bash
adt search_repo -name APP_CORE% -my
```

Restore historical versions:

```bash
adt search_repo -file MY_PACKAGE -restore
```

Restore as staged git commits:

```bash
adt search_repo -file MY_PACKAGE -restore -stage
```

**Prerequisite:** commit index must exist — run `adt patch -target {ENV} -rebuild` if missing.


### adt live_upload

Monitor a local folder and automatically upload changed JS, CSS, and other static files to APEX. Includes automatic minification. Runs in a continuous loop until Ctrl+C.

For full details on flags, minification, monitored directories, and tips, read `references/live-upload.md`.

**Quick reference** – pick one line, run as its own bash call:

Monitor with defaults from config:

```bash
adt live_upload
```

Monitor a specific app's files:

```bash
adt live_upload -app 100
```

Custom folder:

```bash
adt live_upload -app 100 -folder ./my_static/
```

Workspace files instead of app files:

```bash
adt live_upload -workspace
```

List monitored files at startup:

```bash
adt live_upload -show
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


## Examples

Export database objects changed in the last week:

```bash
adt export_db -recent 7
```

Export an APEX app with the typical format set:

```bash
adt export_apex -app 100 -only -full -split -files -rest -readable -recent 0
```

Create and deploy a patch to UAT for a task:

```bash
adt patch -target UAT -patch TASK-123 -create -deploy
```

Recompile invalid objects on DEV:

```bash
adt recompile -target DEV
```
