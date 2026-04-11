---
name: adt-install
description: "ADT (APEX Deployment Tool) installation and setup guide for Mac and Windows. Use this skill whenever a user needs help installing ADT, setting up prerequisites (Python, SQLcl, Instant Client, Git), configuring shell environment variables, creating the adt function/alias, or troubleshooting ADT installation issues. Triggers: install adt, setup adt, adt install, adt setup, configure adt, adt prerequisites, adt requirements, python setup oracle, sqlcl install, instant client setup, adt environment variables, .zshrc adt, adt path, adt not found, adt config -version."
---

# ADT Installation Guide

This skill walks users through installing ADT (APEX Deployment Tool) on macOS or Windows. ADT is a Python-based CLI tool for Oracle APEX and database CI/CD automation — it lives in a cloned Git repo and is invoked via a shell function or batch script.

## Prerequisites Overview

ADT requires these components, installed in this order:

1. **Git** — any client works; GitHub Desktop is easiest for beginners
2. **Python 3.11+** — version 3.11 or higher (3.12, 3.13, 3.14 all work)
3. **SQLcl 24.1+** — Oracle's command-line SQL tool (Java-based)
4. **Oracle Instant Client 19.16+** — only needed for thick connections (on-premise databases or older password modes); can be skipped for OCI cloud databases
5. **Java JDK 17+** — required by SQLcl and Instant Client

## Determine the User's Platform

Ask the user whether they are on **macOS** or **Windows**, then read the appropriate reference file:

- **macOS**: Read `references/mac.md` in this skill directory
- **Windows**: Read `references/windows.md` in this skill directory

Each reference file contains platform-specific step-by-step instructions covering download links, installation commands, PATH configuration, environment variables, the `adt` shell function/batch alias, and verification steps.

## After Installation — First Configuration

Once the environment is set up and `adt config -version` runs successfully, guide the user through creating their first database connection:

### For OCI (cloud) databases:

1. Download the wallet from OCI console
2. Unzip wallet into `config/Wallet_{INSTANCE_NAME}/` inside the project repo
3. Run:
```bash
adt config -create -user USER_NAME -pwd USER_PASSWORD -service SERVICE_NAME -wallet WALLET_NAME -wallet_pwd WALLET_PASSWORD
```

### For on-premise databases:

```bash
adt config -create -schema SCHEMA_NAME -user USER_NAME -pwd USER_PASSWORD -hostname HOST_NAME -service SERVICE_NAME
```

Or with SID instead of service name:
```bash
adt config -create -schema SCHEMA_NAME -user USER_NAME -pwd USER_PASSWORD -hostname HOST_NAME -sid SID
```

This creates `config/connections.yaml` in the project folder. Recommend adding the whole `config/` folder to `.gitignore`. If `ADT_KEY` was set or `-key` was passed, passwords will be encrypted in the YAML file.

## Troubleshooting Tips

- If `adt config -version` fails with "command not found", the shell function/alias is not loaded — check that the profile file was sourced
- If `adt` cannot be created as a function, the user can call ADT directly: `python ~/Documents/ADT/config.py -version` (replace path as needed)
- If `zsh: no such word in event` appears, the password likely contains `!` — wrap it in single quotes
- If Python module errors occur, re-run `pip3 install -r ~/Documents/ADT/requirements.txt --upgrade`
- On Windows, if Git is not found, ensure the Git executable path is in the system PATH (GitHub Desktop installs it in a nested location)
