---
name: adt-update
description: "Guide for updating ADT dependencies — Python oracledb module, SQLcl, and Oracle Instant Client. Use this skill whenever a user needs to upgrade or update oracledb, SQLcl, Instant Client, or any Python module used by ADT, check which versions they have, troubleshoot version mismatches, or keep their ADT environment current. Triggers: update adt, upgrade adt, update oracledb, upgrade oracledb, update sqlcl, upgrade sqlcl, update instant client, upgrade instant client, adt versions, adt config -version, oracledb version, sqlcl version, pip upgrade, adt dependencies, adt outdated."
---

# Updating ADT Dependencies

This skill helps users update the three key external dependencies that ADT relies on: the Python **oracledb** module, **SQLcl**, and **Oracle Instant Client**. These components evolve independently and should be kept reasonably current for security patches, bug fixes, and new Oracle database feature support.

## Check Current Versions First

Before updating anything, have the user check what they currently have:

```bash
adt config -version
```

This prints the versions of Python, oracledb, SQLcl, Java, and Instant Client. Use this output to determine what needs updating.

## What to Update

Read the appropriate reference file based on what the user wants to update:

- **Python oracledb module**: Read `references/oracledb.md`
- **SQLcl**: Read `references/sqlcl.md`
- **Oracle Instant Client**: Read `references/instant-client.md`

If the user wants to update everything, work through all three in the order listed above (oracledb is the quickest, Instant Client is the most involved).

## After Updating

Always verify the update worked by running `adt config -version` again and comparing with the previous output. If ADT uses thick mode connections (on-premise databases), also test an actual database connection with `adt config` to confirm compatibility.
