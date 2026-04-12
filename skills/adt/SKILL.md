---
name: adt
description: "APEX Deployment Tool (ADT) — CLI tool for Oracle APEX and database CI/CD automation. Use this skill whenever the user needs to export database objects, export APEX applications, export data, create or deploy patches, recompile invalid objects, configure ADT connections, or manage Oracle APEX deployment workflows. Triggers: adt, apex deployment, export database, export apex, export data, create patch, deploy patch, adt config, apex ci/cd, database export, patch creation, installation script, deployment order, recompile, invalid objects, compile, broken packages, native compilation, PLSQL_OPTIMIZE_LEVEL."
---

# ADT (APEX Deployment Tool)

ADT is a Python-based CLI tool that automates the export, patching, and deployment of Oracle Database objects and APEX applications. It reads from Git, config files, and the database — it never stores metadata in the database itself.

ADT is invoked via a shell alias: `adt {command} {arguments}`.


## Core Commands


### adt export_db

Export database objects into the repository folder structure.

**Common usage:**

```bash
# Export objects changed in the last 7 days
adt export_db -recent 7

# Export specific object types
adt export_db -type PACKAGE% -type VIEW%

# Export specific objects by name
adt export_db -name MY_PACKAGE -name MY_VIEW

# Export from a specific schema
adt export_db -schema HR

# Delete existing folders before export (clean export)
adt export_db -recent 7 -delete
```

**Key flags:**

| Flag | Purpose |
|---|---|
| `-recent {days}` | Objects changed in the last N days |
| `-type {OBJECT_TYPE%}` | Filter by object type (LIKE syntax, repeatable) |
| `-name {OBJECT_NAME%}` | Filter by object name (LIKE syntax, repeatable) |
| `-schema {SCHEMA_NAME}` | Target schema (`%` for all) |
| `-env {ENVIRONMENT}` | Source environment for connection overrides |
| `-key {PASSWORD}` | Decryption key for encrypted passwords |
| `-delete` | Delete existing folders before export |

**Output structure:**

```
database_{schema}/{object_type}/    # objects organized by type
database_{schema}/data/             # exported data files
database_{schema}/unit_tests/       # unit test packages
database/grants_made/{schema}.sql
database/grants_received/{schema}.sql
```

**Supported object types:** Tables, Views, Indexes, Sequences, Synonyms, Packages, Procedures, Functions, Triggers, Types, Materialized Views, Jobs, Grants, Roles, Directories.


### adt export_apex

Export APEX applications, components, REST services, and workspace files.

**Common usage:**

```bash
# Export everything for all apps
adt export_apex -all

# Export split + readable + embedded for a specific app
adt export_apex -split -readable -embedded -app 100

# Export only recently changed components
adt export_apex -split -readable -embedded -recent 7

# Export REST services
adt export_apex -rest

# Export by developer
adt export_apex -split -readable -embedded -by JKVETINA
```

**Key flags:**

| Flag | Purpose |
|---|---|
| `-full` | Full monolithic application export |
| `-split` | Split export (individual components/pages) |
| `-readable` | Human-readable export format |
| `-embedded` | Embedded Code report |
| `-rest` | REST services and modules |
| `-files` | Application binary files |
| `-files_ws` | Workspace binary files |
| `-all` | Export everything |
| `-recent {days}` | Components changed in the last N days |
| `-by {DEVELOPER}` | Filter by developer |
| `-app {APP_ID}` | Limit to specific application(s) (repeatable) |
| `-ws {WORKSPACE}` | Limit to workspace |
| `-group {GROUP}` | Limit to application group |
| `-release {VERSION}` | Tag export with a release version |

**Output structure:**

```
apex/{workspace}/{app_group}/{app_owner}/{app_id}_{app_alias}/
apex/{workspace}/rest/
apex/{workspace}/workspace_files/
```

**Export types explained:**

- **Full export** — single monolithic SQL file per application, used for full application import.
- **Split export** — individual files for each page, component, and shared component. This is what gets committed and diffed in Git.
- **Readable export** — YAML/JSON formatted export for human review and code search.
- **Embedded Code report** — extracts all PL/SQL and JavaScript embedded in APEX components into a single reviewable file.


### adt export_data

Export table data into CSV files with auto-generated SQL MERGE statements.

**Common usage:**

```bash
# Export specific table data
adt export_data -name CONFIG_PARAMETERS

# Export multiple tables matching a pattern
adt export_data -name CONFIG%

# Export from a specific schema
adt export_data -name LOOKUP% -schema HR
```

**Key flags:**

| Flag | Purpose |
|---|---|
| `-name {TABLE_NAME%}` | Table(s) to export (LIKE syntax, repeatable) |
| `-schema {SCHEMA_NAME}` | Target schema |
| `-env {ENVIRONMENT}` | Source environment |
| `-key {PASSWORD}` | Decryption key |

**Output:**

```
database_{schema}/data/{table_name}.csv   # raw data
database_{schema}/data/{table_name}.sql   # generated MERGE statements
```

The generated SQL MERGE statements handle INSERT and UPDATE by default. DELETE generation is disabled by default and can be enabled in config.


### adt patch

Create and deploy patch files from Git commits. This is the most powerful command — it reads your commits, resolves dependencies, orders objects correctly, and generates deployment scripts.

**Common usage:**

```bash
# Create a patch for a specific task
adt patch -patch TASK-123 -create

# Create and deploy immediately
adt patch -patch TASK-123 -create -deploy

# Show recent commits to select from
adt patch -commits 20

# Show only my commits
adt patch -commits 20 -my

# Create patch from specific commits
adt patch -patch TASK-123 -commit abc1234 def5678 -create

# Deploy to a specific environment
adt patch -patch TASK-123 -create -deploy -target UAT

# Force redeployment
adt patch -patch TASK-123 -deploy -force
```

**Key flags:**

| Flag | Purpose |
|---|---|
| `-patch {CARD_NUMBER}` | Patch code/name (typically the task ID) |
| `-ref {NUMBER}` | Patch reference number |
| `-create` | Create patch file(s) |
| `-deploy` | Deploy immediately after creation |
| `-force` | Force redeployment |
| `-continue` | Continue on DB error instead of rollback |
| `-commits {NUMBER}` | Show N recent commits |
| `-my` | Show only your commits |
| `-by {AUTHOR}` | Show commits by specific author |
| `-commit {HASH(ES)}` | Process specific commit(s) |
| `-ignore {HASH(ES)}` | Exclude specific commit(s) |
| `-target {ENVIRONMENT}` | Target deployment environment |
| `-branch {BRANCH_NAME}` | Override active Git branch |
| `-full {APP_ID(S)}` | Use full export for specific APEX apps |
| `-local` | Use local files instead of Git versions |

**Automatic object ordering:**

ADT resolves dependencies and orders objects in this sequence:
Sequences > Tables > Types > Synonyms > Objects (Views/PL-SQL) > Triggers > Materialized Views > Indexes > Data > Grants > Jobs

**Patch templates and scripts:**

- `config/patch_template/{GROUP}_before/` — executed before an object type group
- `config/patch_template/{GROUP}_after/` — executed after an object type group
- `config/patch_scripts/{CARD_NUMBER}/` — custom scripts for a specific patch

**Output:**

```
patch/{date}.{seq}.{patch_code}/              # patch files
patch/{date}.{seq}.{patch_code}/LOGS_{env}/   # deployment logs
snapshots/                                     # file snapshots
```


## Configuration

### adt config

Manage database connections and project settings.

```bash
# Interactive setup
adt config

# Create new connection(s)
adt config -create

# Create with encrypted passwords
adt config -create -key MySecretKey

# Check component versions
adt config -version
```

**Config files:**

| File | Purpose |
|---|---|
| `config/connections.yaml` | Database connections |
| `config/config.yaml` | Project-wide settings |
| `config/config_{SCHEMA}.yaml` | Schema-specific overrides |
| `config/config_{SCHEMA}_{ENV}.yaml` | Environment + schema overrides |

**Password encryption:** Passwords can be encrypted with a key passed via `-key` flag or the `ADT_KEY` environment variable. Encrypted connection files are safe to commit to the repository.


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
