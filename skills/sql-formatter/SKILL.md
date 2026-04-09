---
name: sql-formatter
description: "SQL formatting and style guide for Oracle views, tables, triggers, sequences, grants, MERGE/data loading, and standalone SQL statements. Use this skill whenever creating, editing, reformatting, or reviewing: SQL views (CREATE OR REPLACE VIEW), CREATE TABLE, CREATE TRIGGER, CREATE SEQUENCE, GRANT statements, MERGE/INSERT data scripts, standalone SELECT/INSERT/UPDATE/DELETE, UNION queries, CTEs (WITH clause), or any .sql file that is NOT a PL/SQL package body or spec. Triggers: SQL view, CREATE VIEW, CREATE TABLE, DDL, SQL formatting, format SELECT, format query, reformat SQL, CTE formatting, WITH clause, UNION ALL, MERGE, GRANT, sequence, trigger, _v.sql files."
---

# SQL Formatter — Views, DDL & Standalone SQL

This skill defines formatting rules extracted from a production Oracle codebase. It covers views, tables, triggers, sequences, grants, MERGE/data loading scripts, and standalone SQL statements. For PL/SQL packages (procedures, functions, package bodies/specs), use the `plsql-format` skill instead — this skill focuses on the SQL side.

**These rules also apply to SQL statements embedded inside PL/SQL code** (SELECT, INSERT, UPDATE, DELETE, MERGE inside packages, procedures, functions, triggers). When SQL appears inside PL/SQL, apply all the formatting rules below but shift the entire statement to match the PL/SQL indentation context. The SQL's internal structure (column alignment, WHERE operators, JOIN conditions, CASE layout, `--` separators) stays exactly the same relative to its own `SELECT`/`FROM`/`WHERE` keywords — only the base indent changes. See `plsql-format` §6 for examples of this embedding.

The style favors **vertical alignment**, **generous whitespace**, and **lowercase identifiers** with **uppercase keywords**. Every file should be scannable at a glance — a developer should immediately see the query structure, logical groupings, and data flow through CTEs.


## 1. Case Conventions

Use **UPPERCASE** for all SQL keywords, built-in functions, data types, and Oracle-specific clauses. Use **lowercase** for all user-defined identifiers: table aliases, column aliases, view names, CTE names.

Keywords that must be uppercase: `CREATE`, `OR`, `REPLACE`, `FORCE`, `VIEW`, `AS`, `WITH`, `SELECT`, `FROM`, `WHERE`, `AND`, `OR`, `NOT`, `IN`, `EXISTS`, `BETWEEN`, `LIKE`, `ESCAPE`, `IS`, `NULL`, `JOIN`, `LEFT`, `RIGHT`, `CROSS`, `INNER`, `OUTER`, `ON`, `UNION`, `ALL`, `INTERSECT`, `MINUS`, `GROUP BY`, `ORDER BY`, `HAVING`, `CASE`, `WHEN`, `THEN`, `ELSE`, `END`, `OVER`, `PARTITION BY`, `ROWS`, `FETCH`, `FIRST`, `ONLY`, `INTO`, `INSERT`, `UPDATE`, `DELETE`, `SET`, `VALUES`, `MERGE`, `USING`, `MATCHED`, `COMMENT`, `TABLE`, `COLUMN`, `INDEX`, `CONSTRAINT`, `MATERIALIZED`, `ASC`, `DESC`, `NULLS`, `LAST`, `DISTINCT`.

Built-in functions stay uppercase: `COUNT`, `SUM`, `AVG`, `MAX`, `MIN`, `NVL`, `COALESCE`, `NULLIF`, `CASE`, `DECODE`, `ROUND`, `TRUNC`, `TO_CHAR`, `TO_DATE`, `TO_NUMBER`, `TRIM`, `LTRIM`, `RTRIM`, `SUBSTR`, `INSTR`, `REPLACE`, `REGEXP_REPLACE`, `REGEXP_SUBSTR`, `UPPER`, `LOWER`, `SYSDATE`, `SYSTIMESTAMP`, `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`, `LISTAGG`, `WITHIN GROUP`, `SYS_CONTEXT`, `APEX_STRING`, `APEX_STRING_UTIL`.

String literals inside quotes remain as-is — do not change their case.


## 2. Indentation

Use **4 spaces** per indentation level. Never use tabs.

- Top-level clauses (`SELECT`, `FROM`, `WHERE`, `GROUP BY`, `ORDER BY`) are at the base indent level (0 for standalone queries, or relative to their CTE/subquery nesting).
- Column lists indent 4 spaces from their `SELECT`.
- `JOIN` aligns with `FROM`. `ON` conditions indent 4 spaces under the `JOIN`.
- `WHERE` conditions: first `AND` indents 4 spaces from `WHERE`.
- Subqueries and CTEs: each nesting level adds 4 spaces.

```sql
SELECT
    t.owner,
    t.object_type,
    t.object_name
FROM all_objects t
WHERE 1 = 1
    AND t.owner         LIKE core.get_constant('G_OWNER_LIKE', 'CORE_CUSTOM')
    AND t.status        = 'INVALID'
ORDER BY
    1, 2, 3;
```


## 3. View Declaration

Always use `CREATE OR REPLACE FORCE VIEW` followed by the view name, then `AS` on the same line. The `SELECT` starts on the next line at the same indent level.

```sql
CREATE OR REPLACE FORCE VIEW core_daily_invalid_objects_v AS
SELECT
    t.owner,
    ...
```

### View naming

Views follow the pattern: `<prefix>_<descriptive_name>_v`. The `_v` suffix identifies the object as a view.

### File termination

Every view file ends with `END;` or the closing `;` of the query, followed by `/` on its own line, then a trailing blank line:

```sql
ORDER BY
    1, 2, 3;
/

```

### COMMENT ON TABLE

When a view has a display label or category, add it after the closing `/`:

```sql
/

COMMENT ON TABLE core_apps_timeline_v IS '15 | Developers Timeline';
```


## 4. SELECT Column Lists

Each column goes on its own line, indented 4 spaces from `SELECT`. Column aliases use `AS` and are lowercase with underscores.

```sql
SELECT
    t.workspace_name                    AS workspace,
    APEX_STRING_UTIL.GET_DOMAIN(t.url)  AS host,
    t.http_method                       AS method,
    t.status_code,
    COUNT(*)                            AS count_
```

When columns have expressions of varying length, align the `AS` keyword at a consistent column position so aliases form a visual column. Short column references that are not renamed do not need `AS`.

### Trailing underscores for aggregates

Aggregate or computed columns that shadow common names use a trailing underscore: `count_`, `error_`, `users_`.

### Style indicator columns

For UI-facing views, add `__style` columns that return presentation hints (typically `'RED'` for problem states):

```sql
    CASE WHEN d.rendering_avg >= 1 THEN 'RED' END AS rendering_avg__style,
    CASE WHEN d.elapsed_avg   >= 2 THEN 'RED' END AS elapsed_avg__style,
```

These always appear immediately after the data column they style.


## 5. Comment Separators in Column Lists

Use a bare `--` on its own line to visually group related columns within a SELECT list. This is a lightweight section separator — it tells the reader "these next columns are a different logical group."

```sql
SELECT
    t.workspace_name                    AS workspace,
    APEX_STRING_UTIL.GET_DOMAIN(t.url)  AS host,
    t.http_method                       AS method,
    t.status_code,
    --
    CASE
        WHEN t.status_code <= 299 THEN 'Success'
        WHEN t.status_code <= 399 THEN 'Redirection'
        WHEN t.status_code <= 499 THEN 'Client Error'
        WHEN t.status_code <= 599 THEN 'Server Error'
        END AS status,
    --
    ROUND(AVG(t.elapsed_sec), 2)        AS elapsed_sec_avg,
    ROUND(MAX(t.elapsed_sec), 2)        AS elapsed_sec_max,
    COUNT(*)                            AS count_
    --
```

Use `--` separators to group: identifiers, then computed/CASE columns, then aggregates, then style columns.


## 6. WHERE Clause

### The WHERE 1 = 1 Pattern

Use `WHERE 1 = 1` as the anchor condition when there are multiple optional or filterable conditions. Each condition goes on its own line with `AND` leading:

```sql
WHERE 1 = 1
    AND t.owner         LIKE core.get_constant('G_OWNER_LIKE', 'CORE_CUSTOM')
    AND t.status        = 'INVALID'
```

### Alignment in WHERE

Align the comparison operators (`=`, `LIKE`, `>=`, `<`, etc.) vertically when conditions reference similar column patterns. Pad column references with spaces so operators line up:

```sql
WHERE 1 = 1
    AND t.request_date  >= core_reports.get_start_date()
    AND t.request_date  <  core_reports.get_end_date()
    AND t.owner         LIKE core.get_constant('G_OWNER_LIKE', 'CORE_CUSTOM')
```

### Optional filter pattern

For views that accept nullable parameters, use `(col = param OR param IS NULL)`:

```sql
WHERE 1 = 1
    AND (t.lock_id      = in_lock_id        OR in_lock_id       IS NULL)
    AND (t.locked_by    = in_locked_by      OR in_locked_by     IS NULL)
```


## 7. JOINs

`JOIN` aligns with `FROM`. Each `ON` condition indents 4 spaces under its `JOIN`. Multiple `ON` conditions stack vertically with `AND` leading:

```sql
FROM user_ords_services s
JOIN user_ords_modules m
    ON m.id             = s.module_id
JOIN user_ords_schemas c
    ON c.id             = m.schema_id
LEFT JOIN user_arguments a
    ON a.object_name    = t.source_name
    AND a.package_name  = t.package_name
    AND a.in_out        = 'IN'
```

Align the `=` signs in ON conditions vertically for readability. Use short, meaningful table aliases (single letter or short abbreviation).

For simple single-condition joins, the `ON` can go on the same line as `JOIN` if it keeps the line short:

```sql
JOIN apex_patches p
    ON p.images_version = r.version_no
```

### CROSS JOIN

Use for cartesian products (typically single-row lookups):

```sql
FROM product_component_version d
CROSS JOIN apex_release r
```


## 8. CTEs (WITH Clause)

CTEs are the primary tool for building complex views. Structure them as a pipeline — each CTE builds on the previous, moving from raw data to final output.

### CTE naming

Use short lowercase aliases: `t`, `d`, `s`, `b`, `g`, `f`, etc. The first/main CTE is typically `t`. Use descriptive names only if you have many CTEs and the letters would be confusing.

### CTE structure

```sql
CREATE OR REPLACE FORCE VIEW core_app_performance_v AS
WITH t AS (
    SELECT
        a.application_id                AS app_id,
        a.page_id,
        ...
    FROM apex_activity_log a
    WHERE 1 = 1
        AND a.view_date     >= core_reports.get_start_date()
        AND a.view_date     <  core_reports.get_end_date()
    GROUP BY ALL
),
d AS (
    SELECT
        t.app_id,
        t.page_id,
        ...
    FROM t
)
SELECT
    d.app_id,
    ...
FROM d
ORDER BY 1, 2;
```

Key patterns:
- `WITH cte_name AS (` on one line — opening parenthesis on same line
- `SELECT` inside indented 4 spaces
- Closing `)` at the CTE indent level, followed by `,` for the next CTE
- Last CTE's `)` has no comma — the final `SELECT` follows
- Blank lines between CTEs are optional but helpful for long queries

### MATERIALIZE hint

For performance-critical CTEs that should not be merged by the optimizer:

```sql
WITH t AS (
    SELECT /*+ MATERIALIZE */
        ...
```


## 9. CASE Expressions

### Searched CASE (CASE WHEN)

Each `WHEN` on its own line, indented 4 spaces from `CASE`. `END` aligns with `CASE`. The alias goes after `END`:

```sql
    CASE
        WHEN t.status_code <= 299 THEN 'Success'
        WHEN t.status_code <= 399 THEN 'Redirection'
        WHEN t.status_code <= 499 THEN 'Client Error'
        WHEN t.status_code <= 599 THEN 'Server Error'
        END AS status,
```

### Simple CASE (CASE field)

```sql
    CASE t.message_level
        WHEN 1 THEN 'E'
        WHEN 2 THEN 'W'
        ELSE TO_CHAR(t.message_level)
        END AS type_,
```

### Inline CASE in aggregates

For short conditional counting/summing, use inline CASE:

```sql
    NULLIF(COUNT(CASE WHEN t.page_view_type = 'Rendering' THEN t.id END), 0) AS rendering_count,
    NULLIF(COUNT(CASE WHEN t.page_view_type = 'Ajax'      THEN t.id END), 0) AS ajax_count,
```

Align the `WHEN` conditions and `THEN` values when you have parallel inline CASEs.


## 10. GROUP BY and ORDER BY

### GROUP BY ALL

Use `GROUP BY ALL` (Oracle 23+) when all non-aggregated columns should be grouped. This is the preferred form — it's concise and self-maintaining:

```sql
    COUNT(*) AS count_
FROM apex_webservice_log t
WHERE 1 = 1
    AND t.request_date  >= core_reports.get_start_date()
GROUP BY ALL
ORDER BY
    1, 2, 3;
```

### Explicit GROUP BY

When `GROUP BY ALL` is not available or you need explicit control:

```sql
GROUP BY
    a.application_id,
    a.page_id,
    a.page_name,
    a.view_date
```

### ORDER BY with positional references

Use column position numbers for ORDER BY — this keeps things concise and avoids repeating long expressions:

```sql
ORDER BY
    1, 2, 3;
```

For single-column ordering: `ORDER BY 1;`

When combined with UNION ALL, ORDER BY comes after the last SELECT and applies to the entire result.


## 11. UNION ALL

Each SELECT block in a UNION ALL is separated by the `UNION ALL` keyword on its own line. All SELECT blocks should have matching column counts and compatible types. Use literal values to align types across blocks:

```sql
SELECT
    t.owner,
    'CONSTRAINT'        AS object_type,
    t.constraint_name   AS object_name,
    t.table_name
FROM all_constraints t
WHERE 1 = 1
    AND t.owner         LIKE core.get_constant('G_OWNER_LIKE', 'CORE_CUSTOM')
    AND t.status        = 'DISABLED'
UNION ALL
SELECT
    t.owner,
    'INDEX'             AS object_type,
    t.index_name        AS object_name,
    t.table_name
FROM all_indexes t
WHERE 1 = 1
    AND t.owner         LIKE core.get_constant('G_OWNER_LIKE', 'CORE_CUSTOM')
    AND (t.status       != 'VALID' OR t.funcidx_status != 'ENABLED')
ORDER BY
    1, 2, 3;
```

Each UNION block gets its own `WHERE 1 = 1` anchor. `ORDER BY` at the end applies to the full result set.


## 12. Subqueries

### Inline subqueries in FROM

Opening parenthesis on same line as `FROM` or after a comma. Closing parenthesis on its own line with the alias:

```sql
FROM (
    SELECT
        t.column_value,
        ROW_NUMBER() OVER (ORDER BY t.column_value) AS r#
    FROM TABLE(APEX_STRING.SPLIT(in_list, ',')) t
) s
```

### Scalar subqueries

For single-value subqueries in SELECT or WHERE, keep them compact when short:

```sql
    (SELECT MAX(a.owner) FROM apex_applications a WHERE a.application_id = core.get_context_app()) AS owner
```


## 13. Window Functions

Window functions (`OVER`) go on the same line as the aggregate when short. For longer partition/order clauses, break across lines:

```sql
    COUNT(*) OVER ()                                        AS total#,
    ROW_NUMBER() OVER (PARTITION BY t.handler_id ORDER BY s.r#) AS r#,
    COUNT(t.handler_id) OVER (PARTITION BY t.handler_id)    AS binds_expected,
```

Align the `OVER` keywords and `AS` aliases when you have multiple window functions in the same SELECT.


## 14. NULL Handling Patterns

### NULLIF for zero-to-null conversion

Wrap aggregates in `NULLIF(..., 0)` when zero should display as blank/null in the UI:

```sql
    NULLIF(COUNT(CASE WHEN t.page_view_type = 'Rendering' THEN t.id END), 0) AS rendering_count,
```

### NVL for default values

Use `NVL` for simple two-argument null replacement:

```sql
    NVL(t.counter, 0) + 1
    NVL(s.activity, 0)
```

### COALESCE for multi-argument chains

Use `COALESCE` when there are more than two fallback values or for readability:

```sql
    COALESCE(in_locked_by, get_user())
```


## 15. Data Cleansing Patterns

### HTML tag stripping

Three-layer cleaning pattern for error messages:

```sql
    REGEXP_REPLACE(
        TRIM(REGEXP_REPLACE(REGEXP_REPLACE(t.error_message, '#\d+', ''), 'id "\d+"', 'id ?')),
        '<[^>]*>', '') AS error_
```

Order: strip numeric IDs → strip quoted IDs → strip HTML tags → TRIM.

### String splitting with APEX_STRING

```sql
JOIN APEX_STRING.SPLIT(t.service_args, ':') s
    ON 1 = 1
WHERE TRIM(s.column_value) IS NOT NULL
```


## 16. CREATE TABLE

### Declaration

Use `CREATE TABLE IF NOT EXISTS` followed by the table name. Column definitions are indented 4 spaces.

### Column alignment

Column definitions use three visual columns, each padded with spaces:
- **Column name**: left-aligned, padded to ~32 characters
- **Data type**: padded to align constraints
- **Constraints/defaults**: inline NOT NULL, DEFAULT values

```sql
CREATE TABLE IF NOT EXISTS xxapp_applications (
    workspace                       VARCHAR2(16)          CONSTRAINT xxapp_applications_nn_workspace NOT NULL,
    app_id                          NUMBER(8,0)           CONSTRAINT xxapp_applications_nn_app_id NOT NULL,
    app_alias                       VARCHAR2(32)          CONSTRAINT xxapp_applications_nn_app_alias NOT NULL,
    app_name                        VARCHAR2(64)          CONSTRAINT xxapp_applications_nn_app_name NOT NULL,
    app_desc                        VARCHAR2(512),
    home_page_id                    NUMBER(8,0),
    is_active                       BOOLEAN               DEFAULT FALSE CONSTRAINT xxapp_applications_nn_is_active NOT NULL,
    created_by                      VARCHAR2(128)         DEFAULT SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
    created_at                      DATE                  DEFAULT SYSDATE,
    updated_by                      VARCHAR2(128)         DEFAULT SYS_CONTEXT('APEX$SESSION', 'APP_USER'),
    updated_at                      DATE                  DEFAULT SYSDATE,
    --
    CONSTRAINT xxapp_applications_pk
        PRIMARY KEY (app_id),
    --
    CONSTRAINT xxapp_applications_uq_workspace_app
        UNIQUE (
            workspace,
            app_id
        )
);
```

### Constraint naming

All constraints are explicitly named using this pattern: `{table}_{type}_{column_or_designation}`:
- Primary key: `{table}_pk`
- Not null: `{table}_nn_{column}`
- Foreign key: `{table}_fk_{referenced_table}`
- Unique: `{table}_uq_{descriptive_name}`

### Inline vs multi-line constraints

NOT NULL constraints go inline with the column definition using the `CONSTRAINT` keyword. Multi-column constraints (PK, FK, UNIQUE) go as separate entries after all columns, each preceded by a bare `--` separator:

```sql
    --
    CONSTRAINT core_report_cols_pk
        PRIMARY KEY (
            view_name,
            column_name
        ),
    --
    CONSTRAINT core_report_cols_fk_view_name
        FOREIGN KEY (view_name)
        REFERENCES core_report_views (view_name)
```

The `PRIMARY KEY`, `FOREIGN KEY`, `REFERENCES`, and `UNIQUE` keywords indent 8 spaces (one level under the `CONSTRAINT` line). Multi-column key lists indent another 4 spaces inside their parentheses.

### DEFAULT values

`DEFAULT` goes after the data type, before any NOT NULL constraint:

```sql
    is_active                       BOOLEAN               DEFAULT FALSE CONSTRAINT xxapp_applications_nn_is_active NOT NULL,
    created_at                      DATE                  DEFAULT SYSDATE,
```

### GENERATED identity columns

```sql
    lock_id                         NUMBER                GENERATED BY DEFAULT AS IDENTITY START WITH 1000 CONSTRAINT core_locks_nn_lock_id NOT NULL,
```

### COMMENT ON TABLE and COLUMN

Every table gets `COMMENT ON TABLE` and `COMMENT ON COLUMN` statements after the closing `);`. Even empty comments are included as placeholders. Separate them with bare `--` lines:

```sql
);
--
COMMENT ON TABLE core_locks IS 'To track DDL events for objects locks';
--
COMMENT ON COLUMN core_locks.lock_id            IS '';
COMMENT ON COLUMN core_locks.object_owner       IS '';
COMMENT ON COLUMN core_locks.object_type        IS '';
```

Align the `IS` keyword in COMMENT ON COLUMN statements by padding the column reference with spaces.

### Audit columns

Tables that track changes include standard audit columns at the end: `created_by`, `created_at`, `updated_by`, `updated_at`. These use `DEFAULT SYS_CONTEXT('APEX$SESSION', 'APP_USER')` and `DEFAULT SYSDATE`.


## 17. CREATE TRIGGER

Triggers follow PL/SQL formatting rules for their body, but the header has its own pattern:

```sql
CREATE OR REPLACE TRIGGER core_locksmith
AFTER DDL ON SCHEMA
DECLARE
    rec             core_locks%ROWTYPE;
BEGIN
    -- ignore procedure scanning objects
    IF ORA_DICT_OBJ_TYPE = 'PROCEDURE' AND ORA_DICT_OBJ_NAME LIKE 'DEPSCAN$%' THEN
        RETURN;
    END IF;

    -- log the event
    core.log_start (
        'event',            ORA_SYSEVENT,
        'object_owner',     ORA_DICT_OBJ_OWNER,
        'object_type',      ORA_DICT_OBJ_TYPE,
        'object_name',      ORA_DICT_OBJ_NAME
    );

    -- evaluate only specific events and object types
    IF ORA_SYSEVENT IN ('CREATE', 'ALTER', 'DROP')
        AND ORA_DICT_OBJ_TYPE IN (
            'TABLE', 'VIEW', 'MATERIALIZED VIEW',
            'PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER'
        )
    THEN
        core_lock.create_lock (
            in_object_owner     => ORA_DICT_OBJ_OWNER,
            in_object_type      => ORA_DICT_OBJ_TYPE,
            in_object_name      => ORA_DICT_OBJ_NAME,
            in_locked_by        => rec.locked_by,
            in_expire_at        => NULL
        );
    END IF;
    --
EXCEPTION
WHEN core.app_exception THEN
    RAISE;
WHEN OTHERS THEN
    core.raise_error();
END;
/
```

Key patterns:
- `CREATE OR REPLACE TRIGGER` on one line with trigger name
- Timing/event (`AFTER DDL ON SCHEMA`, `BEFORE CREATE ON SCHEMA`) on next line
- `DECLARE`/`BEGIN`/`EXCEPTION`/`END` at base indent level
- Body indented 4 spaces, follows plsql-format rules for comments and code blocks
- Named parameter calls with `=>` alignment (same as plsql-format)
- File terminates with `/` on its own line


## 18. CREATE SEQUENCE

Sequences are minimal. Include a commented-out DROP statement as documentation:

```sql
-- DROP SEQUENCE core_lock_id;
CREATE SEQUENCE core_lock_id
    MINVALUE 10000;
/
```

Only specify parameters that differ from Oracle defaults (`MINVALUE`, `START WITH`, etc.). Indent parameters 4 spaces. Terminate with `/`.


## 19. GRANT Statements

Grant files group privileges by type with `--` section headers. Privilege names are padded so the `TO` keyword aligns:

```sql
GRANT CONNECT               TO core;
--
GRANT CREATE CLUSTER                    TO core;
GRANT CREATE DIMENSION                  TO core;
GRANT CREATE JOB                        TO core;
GRANT CREATE MATERIALIZED VIEW          TO core;
GRANT CREATE PROCEDURE                  TO core;
GRANT CREATE SEQUENCE                   TO core;
GRANT CREATE SYNONYM                    TO core;
GRANT CREATE TABLE                      TO core;
GRANT CREATE TRIGGER                    TO core;
GRANT CREATE TYPE                       TO core;
GRANT CREATE VIEW                       TO core;
```

For object grants grouped by type, use section headers:

```sql
--
-- PACKAGE
--
GRANT EXECUTE ON core TO admin;
GRANT EXECUTE ON core_custom TO admin;

--
-- PROCEDURE
--
GRANT EXECUTE ON recompile TO admin;
```

### Grant file naming

Grant files are named by schema: `{SCHEMA}_schema.sql` for system privileges, `{SCHEMA}_grants.sql` for object grants.


## 20. MERGE Statements (Data Loading)

MERGE is the standard pattern for idempotent data loading. The structure follows a specific template:

### Debug header

Each data script starts with a PL/SQL block that outputs a progress message:

```sql
BEGIN
    DBMS_OUTPUT.PUT_LINE('--');
    DBMS_OUTPUT.PUT_LINE('-- MERGE ' || UPPER('core_report_cols'));
    DBMS_OUTPUT.PUT_LINE('--');
END;
/
--
```

### MERGE structure

```sql
MERGE INTO core_report_cols t
USING (
    SELECT 'CORE_APP_HISTORY_V' AS VIEW_NAME, 'T1' AS COLUMN_NAME, '{Mon fmDD, -1}' AS REPORT_NAME FROM DUAL UNION ALL
    SELECT 'CORE_APP_HISTORY_V' AS VIEW_NAME, 'T2' AS COLUMN_NAME, '{Mon fmDD, -2}' AS REPORT_NAME FROM DUAL UNION ALL
    SELECT 'CORE_DAILY_VERSIONS_V' AS VIEW_NAME, 'DB_VERSION' AS COLUMN_NAME, 'DB Version' AS REPORT_NAME FROM DUAL
) s
ON (
    t.view_name = s.view_name
    AND t.column_name = s.column_name
)
WHEN MATCHED THEN
    UPDATE SET
        t.report_name = s.report_name
WHEN NOT MATCHED THEN
    INSERT (
        t.view_name,
        t.column_name,
        t.report_name
    )
    VALUES (
        s.view_name,
        s.column_name,
        s.report_name
    );
--
COMMIT;
```

Key patterns:
- Target alias is `t`, source alias is `s`
- USING subquery: one `SELECT ... FROM DUAL` per row, joined by `UNION ALL`
- For compact tabular data, each SELECT goes on a single line
- Last `SELECT` has no `UNION ALL`
- `ON` conditions indented 4 spaces inside parentheses
- `WHEN MATCHED THEN` and `WHEN NOT MATCHED THEN` at base indent
- `UPDATE SET` assignments indented 8 spaces
- `INSERT` and `VALUES` column lists indented 8 spaces, one column per line
- End with bare `--` separator then `COMMIT;`
- Commented-out DELETE before MERGE: `--DELETE FROM {table};`


## 21. Commented-out Conditions

Use `--AND` (with no space before AND) to comment out optional WHERE conditions, keeping them visible as documentation:

```sql
WHERE 1 = 1
    --AND t.app_group_slug    != 'MASTER'
;
```

This pattern preserves the condition for easy re-enabling during development.


## 22. Trailing Whitespace

Remove all trailing spaces and tabs from every line. Blank lines must be truly empty (zero characters before the newline).


## Quick Reference Checklist

### Views

1. `CREATE OR REPLACE FORCE VIEW` used for all views
2. All SQL keywords and built-in functions are UPPERCASE
3. All user identifiers (aliases, view names, column names) are lowercase
4. 4-space indentation, no tabs
5. Each column on its own line, aliases aligned with `AS`
6. Bare `--` used as column group separators in SELECT lists
7. `WHERE 1 = 1` as anchor for multi-condition WHERE clauses
8. WHERE conditions aligned with `AND` leading, operators aligned vertically
9. JOIN conditions indented under JOIN, `=` signs aligned
10. CTEs structured as a pipeline with short aliases
11. CASE expressions: WHEN/END indented and aligned
12. `GROUP BY ALL` preferred when available
13. `ORDER BY` uses positional references (1, 2, 3)
14. UNION ALL blocks each have their own WHERE clause
15. `NULLIF(..., 0)` wraps aggregates that should be null when zero
16. `__style` columns immediately follow their data column
17. Aggregate columns use trailing underscore: `count_`, `error_`, `users_`

### Tables

18. `CREATE TABLE IF NOT EXISTS` for all tables
19. Column names padded to ~32 characters, types and constraints aligned
20. All constraints explicitly named: `{table}_{type}_{column}`
21. NOT NULL constraints inline, PK/FK/UNIQUE as separate blocks after `--` separator
22. `COMMENT ON TABLE` and `COMMENT ON COLUMN` for every table and column
23. Audit columns (`created_by`, `created_at`, `updated_by`, `updated_at`) at end

### Other DDL

24. Triggers: `CREATE OR REPLACE TRIGGER`, timing on next line, body follows plsql-format
25. Sequences: commented DROP, `CREATE SEQUENCE` with minimal params, `/` terminator
26. Grants: privileges padded to align `TO`, grouped by type with `--` section headers
27. MERGE: debug header, `t`/`s` aliases, `UNION ALL` from DUAL, ends with `COMMIT`

### General

28. File ends with `;` + `/` on its own line + trailing blank line
29. No trailing whitespace on any line
30. Only `--` comments, never `/* */`
