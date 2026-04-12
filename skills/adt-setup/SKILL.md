---
name: adt-setup
description: "ADT (APEX Deployment Tool) installation, project initialization, database connections, and dependency updates. Use this skill whenever a user needs to install ADT, set up prerequisites (Python, SQLcl, Instant Client, Git), configure shell environment, initialize a project repo with ADT config files, create or modify database connections, set up wallets for OCI, update oracledb/SQLcl/Instant Client, or troubleshoot any ADT setup issues. Triggers: install adt, setup adt, adt install, adt setup, configure adt, adt prerequisites, adt requirements, adt connection, connections.yaml, sample.yaml, adt wallet, adt thick, adt environment variables, .zshrc adt, adt.bat, init repo, initialize repo, new project, project setup, adt init, adt gitignore, update oracledb, upgrade sqlcl, update instant client, adt config -version, adt config -autoupdate, adt not found, pip upgrade adt."
---

# ADT Setup Guide

This skill covers three aspects of ADT (APEX Deployment Tool) setup: **installing** it from scratch, **creating database connections**, and **updating** its dependencies. Read the appropriate section based on what the user needs.

**Rule:** After completing any install or update operation, always run `adt config -version` and show the output to the user so they can see the current versions of all components.

---

## 1. Installation

ADT is a Python-based CLI tool that lives in a cloned Git repo and is invoked via a shell function or batch script.

### Prerequisites (install in this order)

1. **Git** — any client works; GitHub Desktop is easiest for beginners
2. **Python 3.11+** — version 3.11 or higher (3.12, 3.13, 3.14 all work)
3. **Java JDK 17+** — required by SQLcl
4. **SQLcl 24.1+** — Oracle's command-line SQL tool; installed inside the Instant Client directory (`$ORACLE_HOME/sqlcl/`)
5. **Oracle Instant Client 19.16+** — only needed for thick connections (on-premise databases or older password modes); can be skipped for OCI cloud databases

### Platform-Specific Instructions

Ask the user whether they are on **macOS** or **Windows**, then read the appropriate reference:

- **macOS**: Read `references/install-mac.md`
- **Windows**: Read `references/install-windows.md`

Each covers download links, installation commands, PATH setup, environment variables, the `adt` shell function/batch alias, and verification with `adt config -version`.

---

## 2. Initialize Project Repository

Before working with ADT in a project, the repo needs config templates and a proper `.gitignore`.

Read `references/init-repo.md` for the full guide covering:

- Locating the ADT installation
- Copying `config.yaml` and `patch*` folders into the project's `config/` directory
- Creating or updating `.gitignore` with ADT-specific patterns

This step is also invoked automatically as part of section 3 (Database Connections), but it can be run independently — for example when setting up a repo before the database is available.

---

## 3. Database Connections

Once ADT is installed and the project repo is initialized, the user needs to create a connection to their Oracle database.

Read `references/connections.md` for the full guide covering:

- Editing the sample connection file directly (do NOT use `adt config -create`)
- Connection types: OCI cloud (wallet), on-premise (hostname/service), on-premise legacy (hostname/SID)
- The `connections.yaml` file structure and all available fields
- Connection file naming — centralized files must match the project folder name exactly
- Multi-schema setups, default schemas, export filters
- Password encryption with `ADT_KEY`
- Wallet configuration for OCI databases
- Thick vs thin connection modes

**Important:** Connection setup must always be done from within the project repository. The `config/connections.yaml` filename and location are critical to ADT.

---

## 4. Updating Dependencies

ADT depends on three external components that should be kept current: the Python **oracledb** module, **SQLcl**, and **Oracle Instant Client**.

### Quick Update (ADT itself)

```bash
adt config -autoupdate
adt config -version
```

This pulls the latest ADT code from Git and shows all component versions.

### Updating Individual Components

Read the appropriate reference:

- **Python oracledb module**: Read `references/update-oracledb.md`
- **SQLcl**: Read `references/update-sqlcl.md`
- **Oracle Instant Client**: Read `references/update-instant-client.md`

If the user wants to update everything, work through all three in that order (oracledb is quickest, Instant Client is most involved).

After any update, verify with `adt config -version`.

---

## Troubleshooting

- `adt: command not found` — shell function/alias not loaded; check that the profile file was sourced
- Direct invocation fallback: `python ~/Documents/ADT/config.py -version`
- `zsh: no such word in event` — password contains `!`; wrap it in single quotes
- Python module errors — re-run `pip3 install -r ~/Documents/ADT/requirements.txt --upgrade`
- Windows Git not found — ensure the Git executable path is in system PATH (GitHub Desktop nests it deep)
- Connection fails after Instant Client update — check `ORACLE_HOME` still points to the right directory
