---
name: plsql-formatter
description: "PL/SQL code formatting and style guide for Oracle packages, procedures, functions, and SQL statements. Use this skill whenever creating, editing, reformatting, or reviewing PL/SQL code (.sql, .pks, .pkb files). Triggers: PL/SQL, Oracle package, stored procedure, SQL formatting, package body, package spec, reformat SQL, code style Oracle."
---

# PL/SQL Formatting & Style Guide

This skill defines formatting rules extracted from a production Oracle PL/SQL codebase. Apply these rules when writing, editing, or reformatting any PL/SQL code to ensure visual consistency and readability.

## General Principles

The style favors **vertical alignment**, **generous whitespace**, and **lowercase identifiers** with **uppercase keywords**. Code reads like a well-typeset document — parameters line up in columns, logical sections are separated by blank lines and dash-comments, and SQL clauses indent consistently. The goal is scanability: a developer should be able to glance at a procedure and immediately see its structure.


## 1. Case Conventions

Use **UPPERCASE** for all Oracle keywords, built-in functions, data types, and PL/SQL control structures. Use **lowercase** for all user-defined identifiers (package names, procedure/function names, variable names, column names, table aliases).

```sql
-- Keywords and types: UPPERCASE
CREATE OR REPLACE PACKAGE BODY core_lock AS
FUNCTION get_user
RETURN core_locks.locked_by%TYPE
AS
BEGIN
    RETURN COALESCE (
        NULLIF(SYS_CONTEXT('USERENV', 'PROXY_USER'), 'ORDS_PUBLIC_USER'),
        REGEXP_REPLACE(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), ':\d+$', '')
    );
END;
```

Keywords that must be uppercase include: `CREATE`, `OR`, `REPLACE`, `PACKAGE`, `BODY`, `AS`, `IS`, `BEGIN`, `END`, `FUNCTION`, `PROCEDURE`, `RETURN`, `DECLARE`, `EXCEPTION`, `WHEN`, `THEN`, `ELSE`, `ELSIF`, `IF`, `LOOP`, `FOR`, `WHILE`, `EXIT`, `IN`, `OUT`, `NOCOPY`, `DEFAULT`, `NULL`, `NOT`, `AND`, `OR`, `SELECT`, `FROM`, `WHERE`, `INTO`, `INSERT`, `UPDATE`, `DELETE`, `SET`, `VALUES`, `ORDER BY`, `GROUP BY`, `HAVING`, `JOIN`, `ON`, `LEFT`, `RIGHT`, `INNER`, `OUTER`, `CROSS`, `UNION`, `ALL`, `FETCH`, `FIRST`, `ROWS`, `ONLY`, `CASE`, `CONSTANT`, `TYPE`, `TABLE`, `OF`, `RECORD`, `CURSOR`, `PRAGMA`, `AUTONOMOUS_TRANSACTION`, `EXCEPTION_INIT`, `DETERMINISTIC`, `RESULT_CACHE`, `ACCESSIBLE BY`, `AUTHID`, `CURRENT_USER`, `COMMIT`, `ROLLBACK`, `RAISE`, `LIKE`, `ESCAPE`, `BETWEEN`, `EXISTS`, `WITH`, `OVER`, `PARTITION BY`, `BOOLEAN`, `TRUE`, `FALSE`, `VARCHAR2`, `NUMBER`, `PLS_INTEGER`, `CHAR`, `CLOB`, `DATE`, `ROWTYPE`, `ROWCOUNT`.

Built-in functions stay uppercase: `COALESCE`, `NVL`, `NULLIF`, `REPLACE`, `REGEXP_REPLACE`, `REGEXP_SUBSTR`, `SUBSTR`, `INSTR`, `UPPER`, `LOWER`, `LTRIM`, `RTRIM`, `TRIM`, `TO_NUMBER`, `TO_CHAR`, `TO_DATE`, `TRUNC`, `SYSDATE`, `SYS_CONTEXT`, `DBMS_OUTPUT`, `APEX_STRING`, `APEX_MAIL`, etc.

String literals inside quotes remain as-is — do not change their case.


## 2. Indentation

Use **4 spaces** per indentation level. Never use tabs.

- Package-level declarations (constants, types, cursors, global variables) indent 1 level (4 spaces) from `CREATE OR REPLACE PACKAGE`.
- Procedure/function body code indents 2 levels (8 spaces) from the package boundary — the subprogram declaration itself is at 1 level (4 spaces), and its internal code is at 2 levels (8 spaces).
- SQL statement clauses inside PL/SQL indent relative to their context.
- Continuation lines for long expressions get extra indentation to show they belong to the parent line.

```sql
CREATE OR REPLACE PACKAGE BODY core AS

    FUNCTION get_slug (                          -- 4 spaces: subprogram declaration
        in_name                 VARCHAR2,        -- 8 spaces: parameters
        in_separator            VARCHAR2    := NULL
    )
    RETURN VARCHAR2
    AS
        v_content               VARCHAR2(32767); -- 8 spaces: local variables
    BEGIN
        v_content := UPPER(in_name);             -- 8 spaces: code body
        --
        IF in_separator IS NOT NULL THEN         -- 8 spaces: control flow
            v_content := REPLACE(v_content, '_', in_separator);  -- 12 spaces: nested block
        END IF;
        --
        RETURN v_content;
    END;
```


## 3. Parameter Formatting

Parameters are formatted in **vertically aligned columns**. Each parameter goes on its own line, indented 8 spaces from the package edge. Parameter names, data types, and default values align into columns using spaces.

```sql
    PROCEDURE create_lock (
        in_object_owner     core_locks.object_owner%TYPE,
        in_object_type      core_locks.object_type%TYPE,
        in_object_name      core_locks.object_name%TYPE,
        in_locked_by        core_locks.locked_by%TYPE       := NULL,
        in_expire_at        core_locks.expire_at%TYPE       := NULL,
        in_hash_check       BOOLEAN                         := TRUE
    );
```

Rules for parameter alignment:

- Parameter names are left-aligned in one column.
- Data types start at a consistent column position (padded with spaces so all types line up).
- Default values (`:= ...`) start at another consistent column, also aligned.
- The closing `)` goes on its own line at the same indent as the opening keyword.
- Use `in_` prefix for IN parameters, `out_` for OUT, `io_` for IN OUT.
- Prefer `%TYPE` and `%ROWTYPE` anchored types over hard-coded types when referencing table columns.


## 4. Constant and Variable Declarations

Constants and variables also use **column alignment** for name, type keyword, data type, and value.

```sql
    -- constants with aligned columns
    master_id                   CONSTANT PLS_INTEGER    := 9000;
    master_debug_page           CONSTANT PLS_INTEGER    := 811;
    master_debug_item           CONSTANT VARCHAR2(30)   := 'P811_LOG_ID';

    -- variables in package body
    g_lock_length       CONSTANT NUMBER     := 20/1440;
    g_lock_rebook       CONSTANT NUMBER     := 10/1440;
    g_check_hash        CONSTANT BOOLEAN    := TRUE;

    -- local variables in a procedure
        v_out               CLOB            := EMPTY_CLOB();
        v_subject           VARCHAR2(256);
        v_cursor            SYS_REFCURSOR;
        v_offset            PLS_INTEGER     := NVL(in_offset, 0);
```

Naming conventions for variables:

- `c_` prefix for local constants inside subprograms.
- `g_` prefix for package-level (global) variables.
- `v_` prefix for local variables.
- `out_` prefix for variables holding output/return values.
- `rec` for `%ROWTYPE` record variables (no prefix needed).
- `in_`, `out_`, `io_` prefixes for parameters.
- `p_` prefix for parameters in APEX callback functions (e.g., `p_username`, `p_password` in authentication functions) — use this only when the APEX API signature requires it.


## 5. Blank Lines and Section Separators

Use **two blank lines** (one empty line visually) between subprogram declarations in both spec and body. This creates clear visual separation between each function/procedure.

```sql
    FUNCTION get_user
    RETURN core_locks.locked_by%TYPE;



    FUNCTION get_audit_trail
    RETURN core_locks.audit_trail%TYPE;



    PROCEDURE create_lock (
```

Within a subprogram body, use a **standalone dash-comment** (`--`) on its own line as a lightweight section separator between logical blocks of code:

```sql
    BEGIN
        rec.locked_by := COALESCE(in_locked_by, get_user());
        IF rec.locked_by IS NULL THEN
            core.raise_error('USER_ERROR');
        END IF;

        -- get current object
        rec.object_payload := get_object();
        --
        IF rec.object_payload IS NULL THEN
            RETURN;
        END IF;

        -- check hash only on objects with source code
        IF in_object_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION') THEN
            rec.object_hash := get_clob_hash(rec.object_payload);
        END IF;
        --
        IF (NOT g_check_hash OR rec.object_hash IS NULL) THEN
            v_hash_check := FALSE;
        END IF;
```

The bare `--` line is used as a visual "soft break" between related statements within the same logical section, while descriptive comments (`-- check hash only on objects`) introduce new logical sections.

Use section header comments with dashes for major groupings inside package specs:

```sql
    --
    -- EXCEPTIONS
    --

    app_exception       EXCEPTION;
    ...

    --
    -- CUSTOM TYPES
    --

    TYPE type_page_items IS RECORD (
```


## 6. SQL Statements Embedded in PL/SQL

**Core principle: SQL statements inside PL/SQL follow the same formatting rules as standalone SQL (defined in the `sql-formatter` skill), but shifted right to match the PL/SQL indentation context.** The SQL structure itself does not change — only the base indent moves.

Think of it this way: take any properly formatted standalone SQL statement, then indent the whole thing to the position where it appears in the PL/SQL code. The internal alignment (column aliases, WHERE operators, JOIN conditions, CASE expressions, `--` separators) stays exactly the same relative to the SQL's own `SELECT`/`FROM`/`WHERE` keywords.

### How indentation works

Inside a package body subprogram, code is at 8 spaces (2 levels). An embedded SQL statement starts its top-level clauses (`SELECT`, `FROM`, `WHERE`, `ORDER BY`, `GROUP BY`) at that same 8-space level, then follows all the `sql-formatter` rules relative to that base:

```sql
        SELECT                                              -- 8 spaces: same as PL/SQL code
            LOWER(c.table_name)     AS table_name,          -- 12 spaces: column list
            LOWER(c.column_name)    AS column_name,
            c.position              AS column_id,
            COUNT(*) OVER()         AS columns#
        FROM user_cons_columns c                            -- 8 spaces: back to SQL base
        JOIN user_constraints n
            ON n.constraint_name    = c.constraint_name     -- 12 spaces: JOIN condition
        WHERE n.table_name          = UPPER(in_table_name)  -- 8 spaces
            AND n.constraint_type   = 'P'                   -- 12 spaces: AND conditions
        ORDER BY c.position;
```

Inside a cursor FOR loop (which adds another nesting level), the SQL base shifts to 12 spaces:

```sql
        FOR c IN (
            SELECT                                          -- 12 spaces: SQL base inside FOR
                t.column_value,                             -- 16 spaces: column list
                t.r#,
                COUNT(*) OVER() AS total#
            FROM (
                SELECT ...                                  -- 16 spaces: subquery adds another level
            ) t
        ) LOOP
            -- body
        END LOOP;
```

### What sql-formatter rules apply inside PL/SQL

All of them. Specifically:

- **Column lists**: one per line, `AS` aliases aligned (sql-formatter §4)
- **`--` separators**: bare `--` between column groups in SELECT (sql-formatter §5)
- **WHERE 1 = 1**: use as anchor for multi-condition WHERE (sql-formatter §6)
- **WHERE alignment**: pad columns so operators (`=`, `LIKE`, `>=`) align vertically (sql-formatter §6)
- **JOINs**: `JOIN` aligns with `FROM`, `ON` indented 4 spaces under JOIN (sql-formatter §7)
- **CTEs**: `WITH ... AS (` structure, short aliases, pipeline pattern (sql-formatter §8)
- **CASE expressions**: WHEN/END indented, inline CASE in aggregates (sql-formatter §9)
- **GROUP BY ALL** preferred, ORDER BY with positional references (sql-formatter §10)
- **UNION ALL**: each block has own WHERE, ORDER BY at end (sql-formatter §11)
- **Window functions**: OVER on same line when short (sql-formatter §13)
- **NULLIF(..., 0)**: for aggregates that should be null when zero (sql-formatter §14)
- **MERGE**: target `t`, source `s`, USING subquery, WHEN MATCHED/NOT MATCHED (sql-formatter §20)

### SELECT INTO (single row)

`INTO` goes on its own line between `SELECT` and `FROM`, at the same indent as `SELECT`:

```sql
        SELECT MAX(a.owner)
        INTO out_owner
        FROM apex_applications a
        WHERE a.application_id = COALESCE(in_app_id, core.get_context_app());
```

### INSERT / UPDATE / DELETE

Follow sql-formatter alignment for SET, VALUES, and WHERE. Align `=` signs in SET columns:

```sql
        UPDATE core_locks t
        SET t.counter           = NVL(t.counter, 0) + 1,
            t.expire_at         = rec.expire_at,
            t.object_payload    = rec.object_payload,
            t.object_hash       = NVL(rec.object_hash, t.object_hash)
        WHERE t.lock_id         = in_lock_id;
```

### MERGE inside PL/SQL

Follows exactly the same structure as standalone MERGE (sql-formatter §20), just indented to the PL/SQL context:

```sql
        MERGE INTO xxapp_applications t
        USING (
            SELECT
                a.workspace,
                a.application_id            AS app_id,
                --
                a.application_name          AS app_name
            FROM apex_applications a
            LEFT JOIN apex_application_pages p
                ON p.application_id         = a.application_id
        ) s
        ON (
            s.app_id = t.app_id
        )
        WHEN MATCHED THEN
            UPDATE SET
                t.workspace         = s.workspace,
                t.app_alias         = s.app_alias
        WHEN NOT MATCHED THEN
            INSERT (
                workspace,
                app_id,
                app_alias
            )
            VALUES (
                s.workspace,
                s.app_id,
                s.app_alias
            );
```

### Cursor FOR Loops

The opening `(` is on the same line as `FOR c IN`, the `SELECT` is indented inside, and `) LOOP` closes at the `FOR` indent level:

```sql
        FOR c IN (
            SELECT
                t.is_modal,
                t.page_name,
                t.page_title
            FROM xxapp_pages t
            WHERE t.app_id      = core.get_app_id()
                AND t.page_id   = core.get_page_id()
        ) LOOP
            -- body
        END LOOP;
```


## 7. Named Parameter Calls

When calling procedures/functions with named parameters, align `=>` vertically:

```sql
        core.create_job (
            in_job_name         => 'REBUILD_APP_' || app_id,
            in_statement        => 'APEX_APP_OBJECT_DEPENDENCY.SCAN(...);',
            in_job_class        => core_custom.g_job_class,
            in_user_id          => USER,
            in_app_id           => app_id,
            in_session_id       => NULL,
            in_priority         => 3,
            in_comments         => 'Rescan ' || app_id
        );
```

For short calls, key-value pairs can go on fewer lines but still use `=>` alignment:

```sql
        core.log_start (
            'recipients',   in_recipients,
            'offset',       in_offset,
            'start_date',   g_start_date,
            'end_date',     g_end_date
        );
```


## 8. Exception Handling

The standard exception block pattern has two forms:

### Full pattern (for procedures/functions that modify data or can encounter various errors):

```sql
    EXCEPTION
    WHEN core.app_exception THEN
        RAISE;
    WHEN OTHERS THEN
        core.raise_error();
    END;
```

For autonomous transactions, add `ROLLBACK`:

```sql
    EXCEPTION
    WHEN core.app_exception THEN
        ROLLBACK;
        RAISE;
    WHEN OTHERS THEN
        ROLLBACK;
        core.raise_error();
    END;
```

### Specific exception pattern (for query functions):

```sql
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    END;
```

`EXCEPTION` and `WHEN` align with `BEGIN`. The handler body indents one level from `WHEN`.


## 9. Package Structure

### File naming

- Spec files: `<package_name>.spec.sql`
- Body files: `<package_name>.sql`

### Package spec structure

```sql
CREATE OR REPLACE PACKAGE <name>
AUTHID CURRENT_USER
AS

    -- constants/types grouped with section headers
    ...



    -- subprogram declarations separated by two blank lines
    FUNCTION get_something
    RETURN VARCHAR2;



    PROCEDURE do_something (
        in_param1       VARCHAR2,
        in_param2       NUMBER := NULL
    );

END;
/
```

### Package body structure

```sql
CREATE OR REPLACE PACKAGE BODY <name> AS

    -- package-level variables/constants first
    g_var1          VARCHAR2(16)   := '';
    g_var2          PLS_INTEGER    := 4;



    -- package-level cursors (if any)
    CURSOR c_something (in_param VARCHAR2) IS
        SELECT ...;



    -- subprogram implementations, same order as spec
    FUNCTION get_something
    ...

END;
/
```

The file ends with `END;` followed by `/` on its own line, then a trailing blank line.


## 10. Control Flow

`IF/ELSIF/ELSE/END IF`, `FOR/LOOP/END LOOP`, `CASE/WHEN/END` follow standard indentation. The keyword and its condition are on the same line. The body indents one level.

```sql
        IF c.locked_by = rec.locked_by THEN
            rec.lock_id     := c.lock_id;
            rec.locked_at   := c.locked_at;
            --
        ELSIF c.expire_at >= SYSDATE THEN
            core.raise_error('LOCK_TIME_ERROR');
            --
        END IF;
```

When a standalone `--` appears just before `ELSIF`, `ELSE`, or `END IF`, it serves as a visual terminator for the preceding block.


## 11. RETURN Placement in Functions

`RETURN` type goes on its own line, aligned with the `FUNCTION`/`PROCEDURE` keyword:

```sql
    FUNCTION get_env
    RETURN VARCHAR2
    AS
    BEGIN
```

For specs, the pattern is the same but with a semicolon:

```sql
    FUNCTION get_env
    RETURN VARCHAR2;
```

When a function has `DETERMINISTIC`, `RESULT_CACHE`, or `ACCESSIBLE BY`, those go on separate lines between `RETURN` and `AS`:

```sql
    FUNCTION get_yn (
        in_boolean              BOOLEAN
    )
    RETURN CHAR
    DETERMINISTIC
    AS
    BEGIN
```


## 12. Comments

**Only use `--` comments.** Never use `/* ... */` block comments anywhere — not for multi-line comments, not for commenting out code, not for documentation headers. Every comment line starts with `--`.

For end-of-line comments, separate them with adequate spacing to form a visual column:

```sql
    flag_apex       CONSTANT CHAR := 'X';     -- error from APEX error handling
    flag_error      CONSTANT CHAR := 'E';     -- error from raise_error
    flag_warning    CONSTANT CHAR := 'W';     -- warning from log_warning
```

Use `-- comment text` on its own line for section/block descriptions. Use bare `--` on its own line as a lightweight separator.


### 12a. Subprogram Summary Comments

Every procedure and function must have a short summary comment (1-2 sentences describing what it does) placed directly above its declaration. The summary is fenced with bare `--` lines above and below:

```sql
    --
    -- Retrieve a parameter value from the configuration table by its key
    --
    FUNCTION get_webservice_parameter (
        in_key                  VARCHAR2
    )
    RETURN VARCHAR2;



    --
    -- Replace a placeholder token in the given string with the supplied value
    --
    PROCEDURE substitute_variable (
        io_string               IN OUT NOCOPY VARCHAR2,
        in_key                  VARCHAR2,
        in_value                VARCHAR2
    );
```

This applies in both package specs and bodies. In the body, the summary goes above the subprogram implementation, not repeated above `BEGIN`. Keep summaries concise — describe the purpose, not the implementation.


### 12b. Block Comments Within Code

Inside a subprogram body, group related statements into logical blocks of **no more than 5 statements** each. Place a short descriptive `--` comment above each block explaining what it does. Separate blocks with a bare `--` line or a blank line.

This helps readers quickly scan a procedure and understand its flow without reading every line. If a block grows beyond 5 statements, look for a natural split point and break it into two commented blocks.

```sql
    BEGIN
        -- validate input parameters
        rec.locked_by := COALESCE(in_locked_by, get_user());
        IF rec.locked_by IS NULL THEN
            core.raise_error('USER_ERROR');
        END IF;

        -- retrieve current object state
        rec.object_payload := get_object();
        --
        IF rec.object_payload IS NULL THEN
            RETURN;
        END IF;

        -- compute hash for source code objects
        IF in_object_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION') THEN
            rec.object_hash := get_clob_hash(rec.object_payload);
        END IF;
        --
        IF (NOT g_check_hash OR rec.object_hash IS NULL) THEN
            v_hash_check := FALSE;
        END IF;

        -- create or extend the lock
        IF rec.lock_id IS NOT NULL THEN
            extend_lock(in_lock_id => rec.lock_id);
        ELSE
            rec.lock_id := lock_seq.NEXTVAL;
            INSERT INTO core_locks VALUES rec;
        END IF;
```

The key principle: a reader should never encounter more than 5 consecutive statements without a comment explaining the intent of that group.


## 13. Trailing Whitespace

Remove all trailing spaces and tabs from every line. No line should end with whitespace characters before the newline. This applies to code lines, comment lines, and blank lines alike. Blank lines must be truly empty (zero characters before the newline).


## 14. Spacing Around Operators

- Spaces around `:=` (assignment): `v_name := 'value';`
- Spaces around `=` (comparison): `WHERE t.lock_id = in_lock_id`
- Spaces around `||` (concatenation): `'prefix' || v_name || 'suffix'`
- Spaces around arithmetic: `20/1440` — division in constants can be compact.
- Space after commas in parameter lists and expressions.
- Space before `(` in function/procedure calls: `core.raise_error ()` — actually NO space before `(` in calls: `core.raise_error()`.
- Exception: `COALESCE (` and `REPLACE (` — built-in functions called at start of a return or assignment sometimes have a space before `(` for readability when the arguments span multiple lines. Single-line calls do not have this space.


## 15. Assignment Alignment

When multiple assignments occur in sequence, align the `:=` operators:

```sql
        rec.lock_id         := core_lock_id.NEXTVAL;
        rec.object_owner    := in_object_owner;
        rec.object_type     := in_object_type;
        rec.object_name     := in_object_name;
        rec.locked_at       := SYSDATE;
        rec.counter         := 1;
```


## 16. PRAGMA Placement

### PRAGMA AUTONOMOUS_TRANSACTION

Goes in the declaration section, either immediately after `AS` (before variables) or after variable declarations. Separated from other declarations by a bare `--`:

```sql
    -- Form 1: before variables
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        --
        rec                 core_locks%ROWTYPE;
        v_hash_check        BOOLEAN := in_hash_check;
    BEGIN
```

```sql
    -- Form 2: after variables
    AS
        v_log_id                core_logs.log_id%TYPE;
        v_next_interval         xxapp_user_pings.next_interval%TYPE;
        --
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
```

### PRAGMA EXCEPTION_INIT

Goes on the **same line** as the exception declaration, separated by a semicolon:

```sql
    app_exception       EXCEPTION; PRAGMA EXCEPTION_INIT(app_exception, -20990);
    assert_exception    EXCEPTION; PRAGMA EXCEPTION_INIT(assert_exception, -20992);
```

### PRAGMA UDF

For functions used primarily in SQL, place after `AS` with a bare `--` separator:

```sql
    RETURN VARCHAR2
    RESULT_CACHE
    AS
        v_found                 PLS_INTEGER;
        out_value               VARCHAR2(4000);
        --
        PRAGMA UDF;
    BEGIN
```

### AUTHID and RESETTABLE

Package-level pragmas go on the line after `CREATE OR REPLACE PACKAGE`, before `AS`. Use `AUTHID CURRENT_USER` for packages that run with the caller's privileges, `AUTHID DEFINER` for packages that run with the owner's privileges. Add `RESETTABLE` when package state should reset on session boundary:

```sql
CREATE OR REPLACE PACKAGE core
AUTHID CURRENT_USER RESETTABLE
AS
```

```sql
CREATE OR REPLACE PACKAGE xxapp_auth
AUTHID DEFINER RESETTABLE
AS
```


## 17. Record-Based DML Patterns

### UPDATE SET ROW

When updating an entire row from a record variable, use `SET ROW = rec`:

```sql
        UPDATE xxapp_user_pings t
        SET ROW = rec
        WHERE t.user_id         = rec.user_id
            AND t.app_id        = rec.app_id;
```

### INSERT VALUES rec

When inserting an entire record variable:

```sql
        INSERT INTO xxapp_user_pings
        VALUES rec;
```

### INSERT INTO ... SET (Oracle 23c)

For explicit column-value assignment on insert:

```sql
        INSERT INTO xxapp_user_pings t
        SET t.ping_id           = core.get_id(),
            t.user_id           = core.get_user_id(),
            t.app_id            = core.get_context_app(),
            t.session_id        = 0,
            t.status            = 'SUCCESS',
            t.next_interval     = g_default_ping_interval,
            t.delivered_at      = SYSDATE,
            t.created_by        = core.get_user_id(),
            t.created_at        = SYSDATE;
```

Align the `=` operators vertically, same as UPDATE SET formatting.

### SQL%ROWCOUNT pattern

Use `SQL%ROWCOUNT` to check DML results and branch. Common pattern for "upsert" logic:

```sql
        UPDATE xxapp_user_pings t
        SET ROW = rec
        WHERE t.user_id         = rec.user_id
            AND t.app_id        = rec.app_id;
        --
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO xxapp_user_pings
            VALUES rec;
        END IF;
```

Separate the DML from the `IF SQL%ROWCOUNT` check with a bare `--`.


## 18. FETCH FIRST in Cursors

For cursor FOR loops that should return limited rows, use `FETCH FIRST N ROWS ONLY`:

```sql
        FOR c IN (
            SELECT
                t.ping_id,
                t.status,
                t.message,
                t.payload
            FROM xxapp_user_pings t
            WHERE t.user_id         = core.get_user_id()
                AND t.delivered_at  IS NULL
            ORDER BY
                t.created_at
            FETCH FIRST 1 ROWS ONLY
        ) LOOP
            -- body
        END LOOP;
```

`FETCH FIRST` goes on its own line, aligned with `ORDER BY`.


## 19. Right-Aligned Trailing Comments on Nested Expressions

When a function call or expression is deeply nested, use right-aligned trailing comments to explain each nesting level:

```sql
        RETURN APEX_UTIL.PREPARE_URL(                                           -- add correct checksum
            REGEXP_REPLACE(                                                     -- remove old checksum
                REPLACE(in_payload, '&APP_SESSION.', core.get_session_id()),    -- replace session
               '([&?])cs=[^&]+',
               '\1', 1, 0, 'i'
            )
        );
```

Align the `--` comments at a consistent column position to form a visual column on the right side.


## 20. Analytical Aggregates

For advanced analytical functions like `KEEP (DENSE_RANK ...)`, keep them on the same line as the aggregate:

```sql
        SELECT MIN(t.next_interval) KEEP (DENSE_RANK FIRST ORDER BY t.created_at DESC)
        INTO v_next_interval
        FROM xxapp_user_pings t
        WHERE t.user_id         = core.get_user_id();
```


## Quick Reference Checklist

When formatting PL/SQL code, verify:

1. All Oracle keywords and built-in functions are UPPERCASE
2. All user identifiers (names, variables, columns) are lowercase
3. 4-space indentation, no tabs
4. Parameters vertically aligned in columns (name, type, default)
5. Constants/variables vertically aligned (name, CONSTANT, type, := value)
6. Two blank lines between subprograms
7. Bare `--` used as section separators within code
8. SQL SELECT columns each on own line, aliases aligned
9. WHERE conditions aligned with `AND`/`OR` leading subsequent lines
10. Named parameters with `=>` aligned vertically
11. Exception blocks follow the standard pattern
12. RETURN type on its own line
13. No trailing whitespace on any line
14. Only `--` comments, never `/* */`
15. Every subprogram has a `--` / `-- summary` / `--` comment header
16. Code blocks of max 5 statements, each with a descriptive comment above
17. Assignments aligned when in sequence
18. File ends with `END;` + `/` + blank line
19. Prefixes: `in_`/`out_`/`io_` for params, `v_` local vars, `g_` globals, `c_` local constants, `rec` for rowtype
20. `AUTHID DEFINER` or `AUTHID CURRENT_USER` with optional `RESETTABLE` on spec
21. `SET ROW = rec` for whole-record UPDATE, `VALUES rec` for whole-record INSERT
22. `SQL%ROWCOUNT` checks separated from DML by bare `--`
23. `FETCH FIRST N ROWS ONLY` on its own line, aligned with `ORDER BY`
24. Right-aligned trailing comments on nested expressions
