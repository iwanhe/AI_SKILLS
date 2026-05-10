---
name: insights-actionable
description: Weekly Claude Code Insights workflow. Triggers /insights, converts the report to structured Markdown in AI/INSIGHTS/, and inserts a pointer task in the task list. Runs automatically every Saturday 20:00 CET via launchd. Invoke with /insights-actionable.
version: "1.0"
tags: [SKILL, ANALYSIS]
license: MIT
updated: 2026-05-10
---
# Insights Actionable

End-to-end weekly Claude Code Insights workflow – fetch, archive, convert, and turn into actionable tasks.

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

### Step 0 – Temp-hide old session JSONL files

`/insights` reads `~/.claude/projects/*/*.jsonl` – one file per session – to compute date ranges and stats. Moving files older than 7 days out of that directory before the run constrains the report to the past week.

**Why not session-meta:** `~/.claude/usage-data/session-meta/` is used for session resumption, not by `/insights`. Manipulating it has no effect on the report date range.

```bash
python3 AI/SKILLS/ANALYSIS/insights-actionable/scripts/prep_sessions.py --hide
```

Prints `Temp-hid: N` (files moved) and `Active: M` (files remaining).

### Step 1 – Regenerate the report

```bash
/usr/local/bin/claude -p "/insights" --permission-mode bypassPermissions \
  > /tmp/insights-trigger.log 2>&1
```

This (re)writes `~/.claude/usage-data/report.html`. **Immediately after the command returns** (success or failure), restore the temp-hidden JSONL files:

```bash
python3 AI/SKILLS/ANALYSIS/insights-actionable/scripts/prep_sessions.py --restore
```

Prints `Restored: N`.

Then verify the file's mtime is within the last 5 minutes:

```bash
HTML=~/.claude/usage-data/report.html
test -f "$HTML" || { echo "ERROR: report.html missing"; exit 1; }
AGE=$(($(date +%s) - $(stat -f %m "$HTML")))
[ "$AGE" -lt 300 ] || echo "WARN: report.html is ${AGE}s old, may be stale"
```

### Step 2 – Pick the next sequence number

```bash
INS=$INSIGHTS_DIR
LAST=$(ls "$INS"/*.md 2>/dev/null | sed -E 's|.*/([0-9]+)-.*|\1|' | sort -n | tail -1)
NEXT=$(printf "%03d" $(( ${LAST:-0} + 10#1 )))
DATE=$(date +%Y-%m-%d)
DEST_MD="$INS/${NEXT}-${DATE}.md"
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
3. `## At a Glance` – two H3 sub-sections from `.glance-section` divs:
   - `### What's working` – content as prose paragraph
   - `### What's hindering you` – content as prose paragraph
   - `### Estimated Satisfaction` table (moved here from friction section) – sorted Satisfied → Likely Satisfied → Dissatisfied → Frustrated; add a `%` column (no leading zero, drop trailing `.0`); right-align Count and % columns
4. `## How You Use Claude Code` – paragraphs from `.narrative` plus the key insight as a `> blockquote`.
5. `## Impressive Things You Did` – intro paragraph + plain bullets (no letter prefix) from `.big-win` blocks.
6. `## Where Things Go Wrong` – intro + sub-sections per friction category, each with plain bullets (no letter prefix); `### Primary Friction Types` table; `### Tool Errors Encountered` table.
7. `## Existing CC Features to Try` – `### Suggested CLAUDE.md Additions` with `#### <name>` blocks (each followed by a fenced code block and `*Why:*` line), then `### Hooks`, `### Custom Skills`, `### MCP Servers` blocks (one fenced code example each).
8. `## New Ways to Use Claude Code` – `### <pattern>` blocks with description, paragraph, and `> blockquote` paste-prompt.
9. `## On the Horizon` – `### <horizon-card>` blocks with description, "Getting started:" line, and `> blockquote` paste-prompt.
10. `## Fun Ending` – the headline as `> blockquote`, the detail paragraph, then:
		- `### Quick wins to try` – prose paragraph from the "C)" glance item
		- `### Ambitious workflows` – prose paragraph from the "D)" glance item

**Critical rendering rule:** if any prompt or example contains placeholder angle brackets like `<file>`, `<path>`, `<name>`, wrap them in backticks (`` `<file>` ``). Bare `<file>` inside a Markdown blockquote breaks Obsidian rendering – it's parsed as an unclosed HTML tag and swallows the next heading.

**Style discipline:**
- N-dash with spaces (`–`), never m-dash. Hyphens only in compound words.
- No emojis. No grandiose adjectives.
- Don't editorialize. Convert what's in the HTML – nothing more.
- Tables: pad spaces so columns align in raw Markdown. Right-align all Count and % columns (`----:`).
- Bullets: plain `- ` prefix, no letter enumeration (A), B), C)).

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
- **No new actionable items** in any of the three target sections (rare). The TODAY.md pointer line still goes in unchanged – it sends the user to the report regardless.
- **Date collision** (running twice on the same Saturday). The destination `<NNN>-<YYYY>-<MM>-<DD>.md` may already exist. Overwrite – this should not happen in normal operation, but if it does, the user explicitly asked for overwrite-without-prompting.
- **TODAY.md missing or malformed.** Don't try to repair – emit an error and stop. The `/today` skill owns that file's structure.

## Why this skill exists

Manual conversion of `~/.claude/usage-data/report.html` is high-friction and easy to skip. A weekly autonomous run captures the trend, converts the report to Markdown in `AI/INSIGHTS/`, and surfaces actionable items as today's tasks – closing the feedback loop between Claude Code's analytics and the brain's task system.
