---
name: adt-setup
description: "ADT (APEX Deployment Tool) installation, configuration, updating, and database connection setup. Use this skill whenever a user needs to install ADT, set up prerequisites (Python, SQLcl, Instant Client, Git), configure shell environment, create or modify database connections, set up wallets for OCI, update oracledb/SQLcl/Instant Client, or troubleshoot any ADT setup issues. Triggers: install adt, setup adt, adt install, adt setup, configure adt, adt prerequisites, adt requirements, adt connection, adt config -create, connections.yaml, adt wallet, adt thick, adt environment variables, .zshrc adt, update oracledb, upgrade sqlcl, update instant client, adt config -version, adt config -autoupdate, adt not found, pip upgrade adt."
---

# ADT Setup Guide

This skill covers three aspects of ADT (APEX Deployment Tool) setup: **installing** it from scratch, **creating database connections**, and **updating** its dependencies. Read the appropriate section based on what the user needs.

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

## 2. Database Connections

Once ADT is installed and `adt config -version` works, the user needs to create a connection to their Oracle database.

Read `references/connections.md` for the full guide covering:

- Connection types: OCI cloud (wallet), on-premise (hostname/service), on-premise legacy (hostname/SID)
- The `adt config -create` command and all its flags
- The `connections.yaml` file structure and how to edit it manually
- Multi-schema setups, default schemas, export filters
- Password encryption with `ADT_KEY`
- Wallet configuration for OCI databases
- Thick vs thin connection modes

---

## 3. Updating Dependencies

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
