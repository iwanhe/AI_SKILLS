---
name: apex-qa
description: "Oracle APEX application quality assurance — standards for page design, component naming, MVC enforcement, and automated checks. Use this skill whenever reviewing APEX applications for quality, creating or auditing APEX pages, checking APEX naming conventions, enforcing MVC separation, reviewing embedded code reports, or setting up APEX QA checklists. Triggers: APEX review, APEX QA, APEX naming, APEX standards, page design review, embedded code, APEX audit, MVC APEX, APEX best practices, APEX page check, APEX component naming, authorization scheme, shared components."
---

# Oracle APEX Quality Assurance

This skill defines quality standards for Oracle APEX applications. It covers the MVC pattern, page design rules, component naming conventions, shared component usage, and automated checks. It does not cover PL/SQL formatting or code quality — those belong to the `plsql-format` and `plsql-code-quality` skills respectively.

The goal is to keep APEX applications maintainable, consistent, and debuggable. Most of the rules below exist because violating them creates problems that are invisible until production — missing auth schemes, scattered inline SQL, unnamed components that nobody can trace.


## MVC Pattern in APEX

The Model-View-Controller pattern is the foundation of a clean APEX application. It promotes separation between business logic and the UI layer.

- **Model** = tables and views. They hold and expose your data.
- **View** = APEX pages, JavaScript, CSS. The UI layer renders data and captures user input, but contains no business logic.
- **Controller** = packages, triggers, jobs. They hold all business logic.

**The rule is simple: no logic on pages.** Queries belong in views. Processes belong in package procedures. Validations and conditions belong in package functions. When logic lives in the database, it is governed, versioned, testable, reusable, and visible in dependency trees.

Why this matters:

- **Catch bugs early.** Database objects produce compilation warnings and show invalidated dependencies. Inline SQL on a page fails silently until a user hits it in production.
- **Readable diffs.** APEX exports are cluttered. A view or package diff is clean and reviewable.
- **Reusable code.** You can reuse a view or a function across pages. You cannot reuse a query hardcoded on a region.
- **Easier impact analysis.** Database dependencies tell you what breaks when a table or column changes. Inline SQL on pages is invisible to the dependency graph.
- **Expert access.** A DBA can tune a view. Asking them to find and fix a query buried on page 347 region 2 is a different story.
- **Testable.** You can write unit tests for packages and validate views with queries. You cannot unit-test inline code on a page.


## Dynamic Views for APEX Regions

The most common objection to using views on APEX regions is that views cannot reference bind variables (`:P100_MONTH`). This is solved by accessing page items via `APEX_UTIL.GET_SESSION_STATE` inside a materialized WITH clause.

### The Pattern

```sql
CREATE OR REPLACE VIEW p100_calendar_v AS
WITH x AS (
    SELECT /*+ MATERIALIZE */
        APEX_UTIL.GET_SESSION_STATE('P100_MONTH')   AS month
    FROM DUAL
)
SELECT
    d.month,
    d.week,
    ...
FROM days d
JOIN x
    ON x.month = d.month
ORDER BY 1, 2;
```

The `/*+ MATERIALIZE */` hint is critical. Without it, `APEX_UTIL.GET_SESSION_STATE` is called for every row in the query, causing serious performance issues. With the hint, the WITH clause is evaluated once and the result is reused.

The APEX region source then becomes just a view reference — no inline SQL, no WHERE filters split between the view and the region.

### Reusable Base Views

When multiple pages share similar filters (e.g. the same date range, customer, or status filter on pages 100, 200, and 300), create a single base view that resolves the correct page item dynamically based on the calling page:

```sql
CREATE OR REPLACE VIEW report_base_v AS
WITH x AS (
    SELECT /*+ MATERIALIZE */
        core.app.get_item('$MONTH')     AS month,
        core.app.get_item('$STATUS')    AS status
    FROM DUAL
)
SELECT
    ...
FROM orders o
JOIN x
    ON (x.month   = o.order_month   OR x.month  IS NULL)
    AND (x.status  = o.order_status  OR x.status IS NULL)
ORDER BY 1;
```

The `get_item('$MONTH')` function replaces `$` with the current page prefix (`P100_`, `P200_`, etc.) by reading `APEX_APPLICATION.G_FLOW_STEP_ID`. This means `report_base_v` works on any page — adding a new filter means changing one view, not three region queries.

### Testing Dynamic Views

You can test these views from PL/SQL outside of APEX by setting session state first:

```sql
APEX_UTIL.SET_SESSION_STATE('P100_MONTH', '03/2024');
SELECT * FROM p100_calendar_v;
```

This makes dynamic views fully testable — something inline region queries can never be.

### When to Use Dynamic Views

- **Page-specific views** (`p100_orders_v`) — when the view is used on one page and references that page's items directly.
- **Base views** (`report_base_v`) — when multiple pages share the same filters and the `get_item('$NAME')` pattern avoids duplication.
- **Static views** (`active_orders_v`) — when no page item filtering is needed. Use these for LOV sources, lookups, and data that does not depend on user context.

For further reading: [The magic of dynamic views in APEX](https://www.oneoracledeveloper.com/2023/03/the-magic-of-dynamic-views.html).


## Page Design Rules

### Page Properties

Every page must have:

- **Page alias.** Use a meaningful alias (e.g. `orders`, `customer-detail`). This enables Friendly URLs and lets you change page numbers without breaking bookmarks.
- **Page group.** Group related pages together (e.g. `Orders`, `Admin`, `Reports`). This is essential for navigation in the APEX Builder.
- **Authorization scheme.** Set on every page, no exceptions. Use authorization schemes backed by a package function, not by application item checks.

### Page Numbering

Use page numbers >= 100 and < 1000. Leave gaps between related pages (e.g. 100, 110, 120) so you can insert new pages nearby later without renumbering. Reserve ranges for functional areas:

- 100–199: core/main pages
- 200–299: administration
- 300–399: reports

Adjust ranges to fit your application. The point is to have a convention, not a specific numbering scheme.

### Page Zero

Do not abuse the global page (page 0). It runs on every page load, so anything placed there has application-wide impact. Use it only for truly global elements (e.g. a navigation bar component, a global notification region). Page-specific logic does not belong here.


## Component Naming Conventions

Consistent naming makes components findable, their purpose obvious, and APEX exports more readable.

### Page Items

Use the standard `P{page_number}_{COLUMN_NAME}` format. Match the column name from the underlying table or view whenever possible. This makes the mapping between page items and data model self-evident.

- Page items: `P100_ORDER_ID`, `P100_CUSTOMER_NAME`
- Global page items: `P0_CURRENT_USER`
- Application items: `G_APP_MODE`, `G_DATE_FORMAT`

Use application items for values that don't need to be accessible in JavaScript. Use global page items (P0_) only when JavaScript access is required.

### Processes

Prefix process names to indicate their purpose and execution point:

| Prefix | Purpose | Execution Point |
|---|---|---|
| `INIT_` | Set up page items, defaults | Pre-rendering |
| `SET_` | Computations, derived values | Pre-rendering |
| `RUN_` / `CALL_` | Execute actions | Pre-rendering |
| `SAVE_` | Form/grid submit handling | Processing |
| `AJAX_` / `CALL_` | AJAX callback handlers | Processing |
| `GET_` / `CHECK_` | Validations | Processing |

### Regions

Use `REGION_` prefix on the Static ID attribute for regions that are referenced in JavaScript or dynamic actions.

### Buttons

Use `BUTTON_` prefix on the Static ID attribute for buttons referenced in JavaScript or dynamic actions.

### Dynamic Actions

Name dynamic actions descriptively — what triggers them and what they do. Avoid the default generated names like "New_1".

### General Rules

- Name everything in uppercase with underscores as word separators.
- Use meaningful names. A well-named component with a proper prefix is better than any comment.
- Turn off item encryption unless the item holds genuinely sensitive data (SSN, password, etc.).


## Shared Components

### LOVs

Create every LOV in Shared Components, never inline on a page item. Back each LOV with a database view so the query is versioned, testable, and reusable.

### Substitution Strings

Use application-level Substitution Strings for values you would otherwise hardcode: date formats, number formats, CSS classes, icon names. Check the escaping options.

### Authorization Schemes

Base authorization schemes on package functions, not on application item comparisons. A function is testable, versionable, and can contain complex logic. An item comparison is brittle and invisible to code review.

### Application Settings

- Enable **Friendly URLs** so the URL shows app/page aliases instead of numbers.
- Enable **Deep Linking** so users can bookmark and share specific pages.
- Configure the **Error Handling Function** in application properties. Never leave error handling to the default — it leaks technical details to users.


## JavaScript and CSS

JavaScript and CSS belong in **application files** or **workspace files**, not inline on pages or the global page. Dynamic actions should call functions from these files rather than containing inline JavaScript.

Small, page-specific tweaks (under ~10 lines) are tolerable inline if they are used only on that page, but this is how technical debt starts. When in doubt, put it in a file.


## Automated QA Checks

Run these checks regularly (at minimum before every pull request) and include the results in the commit:

### Embedded Code Report

Run the Embedded Code Report (Utilities > Embedded Code) to find all SQL and PL/SQL hardcoded on pages. The goal is to minimize this list over time. Every entry is a candidate for extraction into a view or package.

**What to look for:**

- SQL queries on regions — move to views.
- PL/SQL in processes — move to package procedures.
- PL/SQL in validations — move to package functions.
- PL/SQL in computations — move to package functions.
- PL/SQL in dynamic actions — move to package procedures called via `CALL_` AJAX callback.

### APEX Advisor

Run the APEX Advisor (Utilities > Advisor) to catch common issues. Review every finding. Key checks:

- Pages without authorization schemes.
- Deprecated component usage.
- Items with encryption enabled unnecessarily.
- Missing page aliases.
- Security vulnerabilities flagged by the advisor.

### Manual Review Checklist

When reviewing an APEX application or a pull request that includes APEX changes, verify:

- Every page has a page alias, page group, and authorization scheme.
- No inline SQL on page regions — all queries come from views or table/view references.
- No inline PL/SQL in processes — all logic calls package procedures via Invoke API or PL/SQL call.
- Process names follow the prefix convention (`INIT_`, `SET_`, `SAVE_`, etc.).
- Page item names match underlying column names where applicable.
- LOVs are defined in Shared Components with backing views.
- JavaScript and CSS are in application/workspace files, not inline.
- Static IDs use the correct prefix (`REGION_`, `BUTTON_`) where referenced.
- No hardcoded strings that should be Substitution Strings.
- Embedded Code Report has been reviewed and no new inline code was introduced.
- APEX Advisor has been run and findings addressed.
- All relevant APEX exports are present in the commit: split export, readable export, and embedded code report.
