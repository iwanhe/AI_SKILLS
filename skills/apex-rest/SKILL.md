---
name: apex-rest
description: "Oracle APEX RESTful data service standards — module/template/handler design, package-backed handlers, naming conventions, error handling, and maintainability patterns. Use this skill whenever creating, reviewing, or debugging APEX REST services, ORDS modules, RESTful data services, or REST API endpoints in Oracle APEX. Triggers: REST service, ORDS, RESTful data service, REST API, REST module, REST handler, REST template, HTP.P, APEX_JSON, REST endpoint, web service APEX, API APEX, REST debug."
---

# Oracle APEX REST Service Standards

This skill covers the design, naming, and quality standards for RESTful data services in Oracle APEX (ORDS). The core principle is the same as for APEX pages: keep all logic in packages, use the REST handler only as a thin dispatcher, and make everything testable and traceable.

REST services in APEX are notoriously difficult to debug. When you paste code directly into a handler, you lose compilation checks, dependency tracking, and proper error logging. The patterns below eliminate these problems by treating REST handlers the same way we treat APEX page processes — as one-line calls to a package.

For further reading: [Building maintainable REST services in APEX](https://www.oneoracledeveloper.com/2025/09/building-maintainable-rest-services-in.html).


## REST Service Architecture

A REST service in APEX consists of three layers:

- **Module** — groups related templates under a common base path (e.g. `/images/`, `/orders/`).
- **Template** — defines the URI pattern with optional arguments prefixed by `:` (e.g. `user_profile/:id`).
- **Handler** — defines the HTTP method (GET, PUT, DELETE) and the source code to execute.

The full URL is assembled as: `https://{instance}/ords/{schema_alias}/{module_path}/{template_uri}/:args`

The `{schema_alias}` is configured under ORDS Schema Attributes when enabling ORDS for a schema.


## The Package-Backed Handler Pattern

Every REST handler must call a package procedure. The handler source contains nothing but the procedure call — no logic, no queries, no exception handling.

**Handler source (PL/SQL type):**

```sql
xxabc_images.user_profile (
    p_id    => :id
);
```

No `BEGIN`/`END` keywords needed. No parameters defined in the Parameters tab — the `:id` bind variable is passed directly. This is simpler, more flexible, and faster to build.

**The package** contains all logic:

```sql
CREATE OR REPLACE PACKAGE xxabc_images AS

    PROCEDURE user_profile (
        p_id    IN NUMBER
    );

END;
/
```

**Why this matters:**

- **Compilation checks.** If a referenced table or column changes, the package becomes invalid immediately — you know something is broken before anyone calls the service.
- **Dependency tracking.** The database dependency graph includes the package. Inline handler code is invisible to it.
- **Error logging.** The package uses the standard exception handler (`core.raise_error()`), so every failure is logged with full context.
- **Testability.** You can call the procedure directly from PL/SQL to test it without making HTTP requests.
- **Discoverability.** If a service at `/images/user_profile/:id` breaks, the code is in the `xxabc_images.user_profile` procedure. No searching required.


## Naming Conventions

### Modules

Name the module after the domain or functional area it serves. Use the application prefix if applicable. The module name becomes the package name.

| Module name | Package name | Base path |
|---|---|---|
| `xxabc_images` | `xxabc_images` | `/images/` |
| `xxabc_orders` | `xxabc_orders` | `/orders/` |
| `xxabc_reports` | `xxabc_reports` | `/reports/` |

### Templates

Name the template after the resource or action. The template name becomes the procedure name in the package.

| Template URI | Procedure |
|---|---|
| `user_profile/:id` | `xxabc_images.user_profile(p_id => :id)` |
| `order_detail/:order_id` | `xxabc_orders.order_detail(p_order_id => :order_id)` |
| `monthly/:year/:month` | `xxabc_reports.monthly(p_year => :year, p_month => :month)` |

This 1:1 mapping between URI structure and package structure means you can find the code for any service endpoint instantly.

### Handler Arguments

Use the `:argument_name` bind syntax in the template URI. Pass arguments to the package procedure using named parameters prefixed with `p_` (matching the PL/SQL convention for REST handler parameters, distinct from `in_` used for internal package calls).


## Returning JSON

For procedures that return data (not binary files), use `APEX_JSON` or `JSON_OBJECT` to produce output via `HTP.P`.

### Simple cursor to JSON

```sql
PROCEDURE show_orders (
    p_customer_id   IN NUMBER
)
AS
    v_cursor    SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT t.order_id, t.order_date, t.total
        FROM orders_v t
        WHERE t.customer_id = p_customer_id;
    --
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('rowset', v_cursor);
    APEX_JSON.CLOSE_OBJECT;
EXCEPTION
WHEN OTHERS THEN
    core.log_error();
    --
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('rowset', '[]');
    APEX_JSON.WRITE('error', SQLERRM);
    APEX_JSON.CLOSE_OBJECT;
END;
```

The exception handler returns a valid JSON response with an error message instead of letting the service crash with a raw Oracle error. This makes the API consumer's life much easier.

### Serving Binary Files (Images, PDFs)

For binary content, use `WPG_DOCLOAD.DOWNLOAD_FILE` with proper HTTP headers:

```sql
PROCEDURE download (
    p_payload       IN OUT NOCOPY BLOB,
    p_file_name     IN VARCHAR2    := NULL,
    p_file_mime     IN VARCHAR2    := NULL,
    p_file_updated  IN DATE        := NULL
)
AS
BEGIN
    OWA_UTIL.MIME_HEADER(NVL(p_file_mime, 'application/octet'), FALSE);
    HTP.P('Content-length:' || DBMS_LOB.GETLENGTH(p_payload));
    HTP.P('Content-Disposition: attachment; filename=' || NVL(p_file_name, 'file'));
    --
    IF p_file_updated IS NOT NULL THEN
        HTP.P('Cache-Control: max-age=31536000');
        HTP.P('ETag: "' || TO_CHAR(p_file_updated, 'YYYYMMDDHH24MISS') || '"');
    END IF;
    --
    OWA_UTIL.HTTP_HEADER_CLOSE();
    WPG_DOCLOAD.DOWNLOAD_FILE(p_payload);
EXCEPTION
WHEN OTHERS THEN
    core.raise_error();
END;
```

Create this as a shared utility procedure in the package. Each handler procedure that serves files calls `download(...)` with the appropriate payload and metadata. Include cache headers (`Cache-Control`, `ETag`) for content that does not change frequently.


## Error Handling

Every REST handler procedure must follow the standard exception pattern:

```sql
EXCEPTION
WHEN core.app_exception THEN
    RAISE;
WHEN OTHERS THEN
    core.raise_error();
END;
```

For procedures that return JSON, catch the exception and return a structured error response instead of letting the raw Oracle error propagate to the consumer:

```sql
EXCEPTION
WHEN OTHERS THEN
    core.log_error();
    --
    APEX_JSON.OPEN_OBJECT;
    APEX_JSON.WRITE('error', SQLERRM);
    APEX_JSON.CLOSE_OBJECT;
END;
```

Never let a REST service return an unstructured Oracle error message to the consumer. Always wrap errors in JSON.


## Data Dictionary

Use these views to inspect and audit your REST services:

| View | Contents |
|---|---|
| `USER_ORDS_SERVICES` | Aggregated view of modules, templates, and handlers |
| `USER_ORDS_MODULES` | Module definitions |
| `USER_ORDS_TEMPLATES` | Template URIs |
| `USER_ORDS_HANDLERS` | Handler methods and source |
| `USER_ORDS_PARAMETERS` | Declared parameters (if any) |
| `USER_ORDS_SCHEMAS` | ORDS-enabled schemas |

Full join to see everything:

```sql
SELECT *
FROM user_ords_services s
JOIN user_ords_modules m     ON m.id = s.module_id
JOIN user_ords_schemas c     ON c.id = m.schema_id
JOIN user_ords_templates t   ON t.id = s.template_id
JOIN user_ords_handlers h    ON h.id = s.handler_id;
```

Note: only `USER_` and `DBA_` views exist — there are no `ALL_` views for ORDS.


## QA Checklist

When reviewing REST services, verify:

- Every handler source is a single procedure call — no inline logic, no anonymous blocks.
- The package name matches the module name and the procedure name matches the template name.
- All handler procedures use the standard exception pattern with `core.raise_error()` or structured JSON error responses.
- JSON-returning procedures always return valid JSON, even on error.
- Binary file procedures include proper HTTP headers (`Content-Type`, `Content-Length`, `Content-Disposition`).
- Cache headers are set for static or infrequently changing content.
- The package compiles without warnings — invalid packages mean broken services.
- Arguments are passed via named parameters, not positional.
- REST services are included in the ADT export (`adt export_apex -rest`) and committed alongside other APEX changes.
- Services are tested from PL/SQL (procedure call) and from HTTP (actual endpoint) before the pull request.
