---
name: life-in-weeks
description: Render a "Life in Weeks" visualization to a markdown file – one grey square per week from the current week to (birthday + target age), dark for the current week, light for future weeks, 30 columns wide. Obsidian-safe HTML table, inline styles only.
version: "1.0.0"
tags: [SKILL, CHARTS, public]
created: 2026-05-19
updated: 2026-05-19
license: MIT
---
# life-in-weeks

A one-glance reminder of how many weeks are still ahead. Each square is one week of remaining life; the dark cell is the current week, light cells are still to come. Output is a bare HTML `<table>` (Obsidian-safe) wrapped in a minimal frontmatter + H1 wrapper.


## Trigger

Invoke with `/life-in-weeks --birthday YYYY-MM-DD [--target-age N] [--target PATH]`.

- `/life-in-weeks --birthday 1990-01-01` – default target age 80, output to `./life_in_weeks.md`.
- `/life-in-weeks --birthday 1990-01-01 --target-age 90` – override the target age.
- `/life-in-weeks --birthday 1990-01-01 --target ~/notes/me.md` – custom output path.

Birthday can also come from the `LIFE_IN_WEEKS_BIRTHDAY` env var, so `--birthday` becomes optional once set.


## Inputs

| Flag           | What it does                                                                          |
| -------------- | ------------------------------------------------------------------------------------- |
| `--birthday`   | ISO date (`YYYY-MM-DD`). Optional if `LIFE_IN_WEEKS_BIRTHDAY` env var is set.         |
| `--target-age` | Target age in years. Default: `80`.                                                   |
| `--target`     | Output markdown file (overwritten if it exists). Default: `./life_in_weeks.md`.       |

If `--birthday` is omitted and `LIFE_IN_WEEKS_BIRTHDAY` is unset, the script exits with an error.


## Hard rules

- **30 columns wide** – fits comfortably in Obsidian without horizontal scroll. Each row is ~7 months, not a clean year.
- **Current + future only** – the grid starts at the current week and runs to `birthday + target_age`. Lived weeks are not drawn; this is a forward-looking "weeks ahead" view, not a full life span.
- **Two-tone grey** – `#333333` for the current week (the first cell, top-left), `#d4d4d4` for every future week. Exactly one dark cell per render.
- **No tail padding** – the last row is short (only the actual remaining weeks). No padding cells. Obsidian's reading-view theme repaints `<td>` cells regardless of inline `background:transparent`, so the tail must be left empty.
- **No `title=` attributes** – cells have inline style only, no per-week tooltip. Obsidian's reading view doesn't surface them and they bloat the file.
- **Overwrite, no markers** – every run writes the full file, replacing any earlier version. No `<!-- start --> ... <!-- end -->` injection markers; the file is owned end-to-end.
- **Bare `<table>` + inline styles only** – no surrounding `<div>`, no `<style>` block, `cursor:default` on every cell.
- **Output frontmatter** – `title: Life in Weeks`, `created`/`updated` set to today, `tags: [ABOUT, LIFE]`. H1 on the line immediately after the closing `---` (no blank line). Bumps `updated:` every run.


## Pipeline

- 1) **Resolve birthday** – `--birthday` wins; otherwise `$LIFE_IN_WEEKS_BIRTHDAY`. Hard error if neither yields a date.
- 2) **Compute span** – `end = birthday + target_age years` (Feb-29 birthdays fall back to Feb-28 in non-leap target years). `weeks_total = (end − birthday).days // 7`.
- 3) **Compute lived / ahead** – `weeks_lived = min(weeks_total, max(0, (today − birthday).days // 7))`; `weeks_ahead = weeks_total − weeks_lived`. Clamped so future birthdays render the full span ahead and over-target ages render an empty grid.
- 4) **Render** – linear `offset` 0..weeks_ahead-1 packed left-to-right, top-to-bottom into a 30-wide grid. Offset 0 (current week) = dark, offsets 1..N (future) = light. The last row is short (no padding cells). Lived weeks are never drawn.
- 5) **Write** – overwrite `--target` with frontmatter + H1 + single-line bold caption (`**Birthday:** …, target age N · **Ahead:** N weeks`) + HTML table.


## Script

Stdlib-only Python. Save as `life_in_weeks.py` and run with `python3 life_in_weeks.py --birthday YYYY-MM-DD`.

```python
#!/usr/bin/env python3
"""Generate the Life in Weeks visualization as Obsidian-safe HTML.

One grey square per week from the current week to (birthday + target age years).
The current week is dark; future weeks are light. 30 cells per row.
"""
import argparse
import os
import sys
from datetime import date
from pathlib import Path

COLUMNS = 30
CURRENT_COLOR = '#333333'
FUTURE_COLOR = '#d4d4d4'

TABLE_STYLE = (
    'border-collapse:separate;border-spacing:3px;'
    'width:auto;table-layout:fixed;'
)
CELL_STYLE = (
    'width:18px;min-width:18px;max-width:18px;height:18px;'
    'padding:0;border:0;border-radius:3px;cursor:default;background:{bg};'
)


def years_after(d: date, years: int) -> date:
    try:
        return d.replace(year=d.year + years)
    except ValueError:
        return d.replace(year=d.year + years, day=d.day - 1)


def render(birthday: date, target_age: int, today: date) -> tuple[str, int, int]:
    end = years_after(birthday, target_age)
    weeks_total = (end - birthday).days // 7
    weeks_lived = min(weeks_total, max(0, (today - birthday).days // 7))
    weeks_ahead = weeks_total - weeks_lived

    rows = []
    n_rows = (weeks_ahead + COLUMNS - 1) // COLUMNS
    for ri in range(n_rows):
        cells = []
        for ci in range(COLUMNS):
            offset = ri * COLUMNS + ci
            if offset >= weeks_ahead:
                break
            bg = CURRENT_COLOR if offset == 0 else FUTURE_COLOR
            style = CELL_STYLE.format(bg=bg)
            cells.append(f'<td style="{style}"></td>')
        rows.append('    <tr>\n      ' + '\n      '.join(cells) + '\n    </tr>')

    html = '\n'.join([
        f'<table style="{TABLE_STYLE}">',
        '  <tbody>',
        *rows,
        '  </tbody>',
        '</table>',
    ])
    return html, weeks_total, weeks_lived


def write_target(target, html, birthday, target_age, weeks_total, weeks_lived, today):
    target.parent.mkdir(parents=True, exist_ok=True)
    weeks_ahead = weeks_total - weeks_lived
    body = '\n'.join([
        '---',
        'title: Life in Weeks',
        f'created: {today.isoformat()}',
        f'updated: {today.isoformat()}',
        'tags: [ABOUT, LIFE]',
        '---',
        '# Life in Weeks',
        '',
        (f'**Birthday:** {birthday.isoformat()}, target age {target_age} · '
         f'**Ahead:** {weeks_ahead} weeks'),
        '',
        html,
        '',
    ])
    target.write_text(body, encoding='utf-8')


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description='Life in Weeks – one grey square per week from the current '
                    'week to birthday + target age. Current = dark, future = light.',
    )
    ap.add_argument('--birthday', help='ISO date (YYYY-MM-DD); default $LIFE_IN_WEEKS_BIRTHDAY.')
    ap.add_argument('--target-age', type=int, default=80, help='Target age in years (default: 80).')
    ap.add_argument(
        '--target', type=Path, default=Path('./life_in_weeks.md'),
        help='Output markdown file; overwritten if exists (default: ./life_in_weeks.md).',
    )
    args = ap.parse_args(argv)

    bday_str = args.birthday or os.environ.get('LIFE_IN_WEEKS_BIRTHDAY')
    if not bday_str:
        sys.exit('birthday not provided – pass --birthday YYYY-MM-DD or set LIFE_IN_WEEKS_BIRTHDAY')
    try:
        birthday = date.fromisoformat(bday_str)
    except ValueError:
        sys.exit(f'invalid birthday: {bday_str!r}; expected YYYY-MM-DD')

    today = date.today()
    html, weeks_total, weeks_lived = render(birthday, args.target_age, today)
    write_target(args.target, html, birthday, args.target_age, weeks_total, weeks_lived, today)

    weeks_ahead = weeks_total - weeks_lived
    sys.stderr.write(
        f'wrote life-in-weeks chart -> {args.target}\n'
        f'  birthday   : {birthday.isoformat()}\n'
        f'  target age : {args.target_age}\n'
        f'  ahead      : {weeks_ahead} / {weeks_total} weeks\n'
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
```


## Examples

**1. First run with the default target age.**

```
python3 life_in_weeks.py --birthday 1990-01-01
```

Computes 4174 total weeks for target age 80 and writes `./life_in_weeks.md` with ~50 rows × 30 columns (only weeks ahead). Stderr logs birthday, target age, and `ahead / total` weeks.

**2. Custom target age, custom output path.**

```
python3 life_in_weeks.py --birthday 1990-01-01 --target-age 90 --target ~/notes/life_90.md
```

Same birthday, 90-year span, separate output file. Useful for "what if I push for 90?" scenarios without overwriting the canonical file.

**3. Using the env var.**

```
export LIFE_IN_WEEKS_BIRTHDAY=1990-01-01
python3 life_in_weeks.py
```

Once the env var is set in your shell rc, no flag needed.


## Reporting

End-of-run summary (info-only, to stderr):

- A) Inputs – resolved birthday, target age, output path
- B) Computed – `weeks_ahead / weeks_total` and grid dimensions (cols × rows)
- C) File – wrote/overwrote `<target>`

