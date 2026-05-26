---
created: 2026-04-26
name: insights-actionable
description: Weekly Claude Code Insights workflow. Triggers /insights, converts the report to structured Markdown in AI/INSIGHTS/, appends 5 next-week goals to KANBAN_INSIGHTS.md, and sends a ready-ping iMessage when done. Runs automatically every Saturday 20:00 CET via launchd. Invoke with /insights-actionable.
version: "1.2"
tags: [SKILL, ANALYSIS]
license: MIT
updated: 2026-05-24
---
# Insights Actionable

End-to-end weekly Claude Code Insights workflow – fetch, archive, convert, and turn into actionable tasks.

## Stamp

On success, run: `python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SCRIPTS/skills_log.py stamp insights-actionable`

## Trigger

- Manual: `/insights-actionable`
- Automated: `~/Library/LaunchAgents/com.brain.insights-actionable.plist` runs every Saturday 20:00 CET. Plist content reproduced under §Scheduling below.

## Inputs

- None. The skill regenerates the source HTML by invoking Claude Code's built-in `/insights` command.

## Configuration

Before running, confirm these two paths with the user if they are not already known from context:

- `BRAIN_ROOT` – absolute path to the user's brain/notes root (the git repo that holds CLAUDE.md, task lists, etc.)
- `INSIGHTS_DIR` – absolute path to the folder where numbered insight reports are stored

Do not assume or hardcode these. Ask once at the start of any fresh session.

## Outputs

- A) `AI/INSIGHTS/<NNN>-<YYYY>-<MM>-<DD>.md` – clean Markdown conversion of the report

## Workflow

### Step 0a – Ensure permissions

Sync the skill's permission manifest into `.claude/settings.local.json` so the iMessage send and helper scripts don't block on a prompt during unattended runs:

```bash
python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SCRIPTS/ensure_skill_permissions.py insights-actionable
```

### Step 0 – Temp-hide old session JSONL files

`/insights` reads `~/.claude/projects/*/*.jsonl` – one file per session – to compute date ranges and stats. Moving files older than 7 days out of that directory before the run constrains the report to the past week.

**Why not session-meta:** `~/.claude/usage-data/session-meta/` is used for session resumption, not by `/insights`. Manipulating it has no effect on the report date range.

```bash
python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SKILLS/ANALYSIS/insights-actionable/scripts/prep_sessions.py --hide
```

Prints `Temp-hid: N` (files moved) and `Active: M` (files remaining).

### Step 1 – Regenerate the report

```bash
/usr/local/bin/claude -p "/insights" --permission-mode bypassPermissions > /tmp/insights-trigger.log 2>&1
```

This (re)writes `~/.claude/usage-data/report.html`. **Immediately after the command returns** (success or failure), restore the temp-hidden JSONL files:

```bash
python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SKILLS/ANALYSIS/insights-actionable/scripts/prep_sessions.py --restore
```

Prints `Restored: N`.

Then verify the file exists and is fresh (helper exits non-zero if missing; prints WARN to stdout if older than 5 min):

```bash
python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SKILLS/ANALYSIS/insights-actionable/scripts/insight_paths.py verify-report
```

### Step 2 – Pick the next sequence number

The helper computes the next zero-padded sequence + today's ISO date and prints the absolute destination path. Capture stdout into the LLM step's `DEST_MD` variable for use in Step 3:

```bash
python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SKILLS/ANALYSIS/insights-actionable/scripts/insight_paths.py next-path --insights-dir <INSIGHTS_DIR>
```

Format is fixed: zero-padded 3-digit sequence + ISO date (e.g. `002-YYYY-MM-DD.md`).

### Step 3 – Convert HTML to Markdown

**Delegate to a subagent.** The HTML is 60k+ bytes – reading it into the parent context wastes tokens. Spawn a Sonnet subagent with the full conversion prompt; it reads the HTML, writes the MD, and returns a one-line confirmation. The parent session never sees the HTML content.

The subagent should read `~/.claude/usage-data/report.html` and produce `$DEST_MD`. Follow the structure of previous reports in `$INSIGHTS_DIR` as the canonical template – do NOT use any HTML-to-Markdown library blindly; the source HTML is heavily styled and a literal conversion creates noise.

Required output structure (sections in this order):

1. YAML frontmatter:
   ```
   ---
   title: Claude Code Insights – <NNN>
   date: <YYYY-MM-DD>
   range: <start> → <end>
   messages: <count>
   sessions: <count>
   ---
   ```
   Pull `<start>`, `<end>`, `<count>` values from the HTML's subtitle line and stats row.
2. `# Claude Code Insights` H1 with the subtitle line beneath it.
3. `## What's working` – content as prose paragraph, followed by:
   - `### How You Use Claude Code` – paragraphs from `.narrative`, then `### Key pattern` header above the key insight as a `> blockquote`
   - `### Impressive Things You Did` – intro paragraph + plain bullets (no letter prefix) from `.big-win` blocks
4. `## What's hindering you` – content as prose paragraph plus the project area table, followed by:
   - `### Estimated Satisfaction` table – sorted Satisfied → Likely Satisfied → Dissatisfied → Frustrated; add a `%` column (integer value only, `%` sign in header only); right-align Count and % columns
   - `### Where Things Go Wrong` – intro + sub-sections per friction category as `####` headers, each with plain bullets (no letter prefix); `### Primary Friction Types` table with `%` column (integer value only); `### Tool Errors Encountered` table with `%` column (integer value only); right-align Count and % in all three tables
7. `## Existing CC Features to Try` – `### Suggested CLAUDE.md Additions` with `#### <name>` blocks (each followed by a fenced code block and `**Why:**` line), then `### Hooks`, `### Custom Skills`, `### MCP Servers` blocks (one fenced code example each).
8. `## New Ways to Use Claude Code` – `### <pattern>` blocks with description, paragraph, and `> blockquote` paste-prompt.
9. `## On the Horizon` – `### <horizon-card>` blocks with description, "Getting started:" line, and `> blockquote` paste-prompt.
10. `## Fun Ending` – the headline as `> blockquote`, the detail paragraph, then:
		- `#### Quick wins to try` – prose paragraph from the "C)" glance item
		- `#### Ambitious workflows` – prose paragraph from the "D)" glance item

### Step 3b – Read past-7-days LESSONS_LEARNED

`/insights` analyses Claude Code's session telemetry – tool calls, errors, friction patterns it can infer from the JSONL stream. It cannot see `AI/LESSONS_LEARNED/`, which captures rule violations and user corrections that happened *inside* assistant prose (style, scope, enumeration, disjunction). These two evidence streams are complementary; the LL stream is the only place where "rule existed but got violated" patterns surface.

List files modified in the past 7 days under `AI/LESSONS_LEARNED/`:

```bash
find AI/LESSONS_LEARNED -type f -name "*.md" -mtime -7 -print
```

Read every file in the list (they are small – 30–80 lines each). For each, capture:

- The H1 title.
- The first non-blank line under `## Prevention rule`.
- The opening sentence of `## What went wrong` (gives the pattern, not the fix).

This is judgment work – run on Opus per the model rule in `AI/RULES/FEEDBACK/style.md § Consolidation work runs on Opus`. The same skill model applies; no re-invocation needed if `/insights-actionable` is already on Opus.

The LL pile feeds the goal synthesis in Step 3c, not the report MD in Step 3.

### Step 3c – Append 5 next-week goals to KANBAN_INSIGHTS.md

After the report file is written, synthesize five concrete, ambitious-but-doable goals from the whole report (friction, horizon cards, ambitious workflows, quick wins) **plus the LL pile from Step 3b** that would meaningfully move the system forward if achieved in seven days.

LL pattern rule: if 2+ lessons in the past 7 days share a theme (same rule, same skill, same file class, same friction type), one of the 5 goal slots MUST be the systemic fix for that theme – not patching one symptom. Name the theme explicitly in the goal's first move. Single-occurrence lessons are evidence but do not force a slot.

Append them to `TASKS/BACKLOG/KANBAN_INSIGHTS.md` under the `## Backlog` section. If the `## Backlog` section doesn't exist, create it (Kanban file format: frontmatter + H1 + `## In Progress` / `## Waiting` / `## Backlog` / `## Done`).

Each goal is an unchecked task bullet:

```
- [ ] **[<NNN>] <Short goal title>**
   First move: <one-sentence concrete first action — named skill, hook, file, or script>.
   Done when: <observable outcome that proves the goal landed, ideally tied to a metric in the next insights report>.
```

- `<NNN>` is the insight sequence number from Step 2 (e.g. `003`). It marks provenance so re-runs can append more goals without renumbering.
- Each goal must be specific (named skill / hook / file / metric), not generic ("improve reliability").
- Bias toward eliminating the top friction sources surfaced in §What's hindering you and shipping the highest-leverage horizon-card item.
- No filler, no warm-up tasks – every item should feel like a small win worth bragging about.
- Append only – never rewrite or renumber existing items in the section. Older insight bullets stay until Jan checks them off or `/refresh-pipeline` archives them.

**Critical rendering rule:** if any prompt or example contains placeholder angle brackets like `<file>`, `<path>`, `<name>`, wrap them in backticks (`` `<file>` ``). Bare `<file>` inside a Markdown blockquote breaks Obsidian rendering – it's parsed as an unclosed HTML tag and swallows the next heading.

**Style discipline:**
- N-dash with spaces (`–`), never m-dash. Hyphens only in compound words.
- No emojis. No grandiose adjectives.
- Don't editorialize. Convert what's in the HTML – nothing more.
- Tables: pad spaces so columns align in raw Markdown. Right-align all Count and % columns (`----:`).
- Bullets: plain `- ` prefix, no letter enumeration (A), B), C)).

### Step 4 – Send ready-ping iMessage

After the report MD is written and the goals are appended, send **exactly one** iMessage to `jan.kvetina@gmail.com` via `mcp__Read_and_Send_iMessages__send_imessage` confirming the report is ready. Keep it to a one-line ping plus the file path — no summary, no goals body:

```
Insights report <NNN> is ready – <DEST_MD>
```

`<NNN>` is the sequence number from Step 2; `<DEST_MD>` is the absolute path written in Step 3. Send the ping directly on the first call — do NOT send a "test"/"ping"/connectivity-probe message first; the tool is already permissioned (see `permissions.json`) and needs no warm-up.

This is the only notification the skill emits — if it is skipped, the weekly run completes silently and the user never learns the report landed. Send it even on a quiet week.

## Scheduling

To run this skill automatically every week, give Claude the following prompt (fill in your paths):

```
Set up a launchd agent at ~/Library/LaunchAgents/com.brain.insights-actionable.plist that runs /insights-actionable every Saturday at 20:00 local time. Use `claude -p "/insights-actionable" --permission-mode bypassPermissions` inside <YOUR_BRAIN_ROOT>, logging stdout and stderr to <YOUR_LOG_PATH>. Write the plist, load it with launchctl, and verify the agent is registered.
```

On Linux/WSL, use a cron job instead:

```
Set up a cron job that runs /insights-actionable every Saturday at 20:00 local time. Use `claude -p "/insights-actionable" --permission-mode bypassPermissions` inside <YOUR_BRAIN_ROOT>, logging to <YOUR_LOG_PATH>.
```

Run the skill manually at least once before enabling the schedule to confirm the report generates correctly and lands in the expected location.

## Edge cases

- **`/insights` command unavailable.** If `claude -p "/insights"` fails or doesn't update `report.html`, run the Step 1 tmp restore first (the archive move in Step 0 is permanent and stands regardless), then log the failure and exit non-zero.
- **No new actionable goals** synthesized (rare). Still write the report to `AI/INSIGHTS/` – it stands on its own; just skip the goal append.
- **Date collision** (running twice on the same Saturday). The destination `<NNN>-<YYYY>-<MM>-<DD>.md` may already exist. Overwrite – this should not happen in normal operation, but if it does, the user explicitly asked for overwrite-without-prompting.
- **`TASKS/BACKLOG/KANBAN_INSIGHTS.md` missing.** Create it with the standard Kanban frontmatter and `## Backlog` section header, then append the goals.

## Why this skill exists

Manual conversion of `~/.claude/usage-data/report.html` is high-friction and easy to skip. A weekly autonomous run captures the trend, converts the report to Markdown in `AI/INSIGHTS/`, and surfaces actionable items as today's tasks – closing the feedback loop between Claude Code's analytics and the brain's task system.

## Examples

Run the full weekly workflow manually (regenerates the report, converts it, appends next-week goals):

```bash
/insights-actionable
```

The skill takes no arguments – it fires the same way when launchd triggers it every Saturday 20:00 CET:

```bash
/usr/local/bin/claude -p "/insights-actionable" --permission-mode bypassPermissions
```

