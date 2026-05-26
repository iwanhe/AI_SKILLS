---
created: 2026-04-24
updated: 2026-05-23
name: devils
version: "1.0.0"
tags: [decision, analysis, council, red-team, public]
description: "Pressure-test a decision by dispatching five adversarial devils (Skeptic, Architect, Scout, Stranger, Operator) in parallel. Each attacks the idea from a different angle, then anonymously peer-reviews the others. The Warden synthesizes a markdown verdict and writes it to a user-chosen path. Based on Andrej Karpathy's LLM Council methodology. MANDATORY TRIGGERS: '/devils', 'devils this', 'pressure-test this', 'stress-test this', 'war-room this', 'red-team this', 'break this idea'. STRONG TRIGGERS (use when paired with a real decision and tradeoffs): 'should I X or Y', 'which option', 'is this the right move', 'I'm torn between', 'what would you do', 'validate this', 'get multiple perspectives', 'I can't decide'. DO NOT trigger on: factual lookups ('what's the capital of X'), simple yes/no questions, creation tasks ('write me a tweet'), summarization, or 'should I' without a real tradeoff (e.g. 'should I use markdown' is not a devils question). Expensive – eleven-plus agent dispatches per run. Skip for trivia, factual lookups, or anything that doesn't carry real consequences."
based_on: "Andrej Karpathy's LLM Council methodology – multiple advisors dispatched in parallel, anonymized peer review, single chairman synthesis. The five-role panel, sharpening round, low-signal guard, file output, and Warden synthesis are local extensions."
---
# Devils

Pressure-test a decision through five adversarial devils. Each attacks from a different angle. They peer-review each other anonymously. The Warden writes the verdict.

Use this when a decision matters and you want it broken before you commit. Skip it for one-right-answer questions, casual sanity checks, or anything where the cost of being wrong is small.

The shape of the run – parallel advisors, anonymized peer review, single chairman synthesis – is adapted from Andrej Karpathy's LLM Council. The five named roles, the sharpening round, the low-signal guard, and the file-output verdict are local extensions.


## Stamp

On success, run: `python3 /Users/dobby/Library/CloudStorage/Dropbox/BRAIN/AI/SCRIPTS/skills_log.py stamp devils`

## When to run

Good devils questions:

- "Should I launch a $97 workshop or build a $497 course?"
- "Which of these three positioning angles is strongest?"
- "I'm thinking of pivoting from X to Y. Am I crazy?"
- "Here's my landing page copy. What's weak?"
- "Should I hire a VA or build the automation first?"

Bad devils questions:

- "What's the capital of France?" – factual lookup, one right answer.
- "Write me a tweet about X." – creation task, not judgment.
- "Summarize this article." – processing task, not a decision.
- "Should I use markdown?" – no real tradeoff, no stakes.

The devils shine when there's genuine uncertainty and the cost of a bad call is high. If you already know the answer and just want validation, the panel will tell you things you don't want to hear. That's the point.


## The five devils

### Skeptic

Hunts for the fatal flaw. Assumes the idea has a hidden problem and tries to find it. If everything looks solid, digs deeper. Not a doomer – the friend who saves you from a bad deal by asking the question you were avoiding.

### Architect

Challenges the framing itself. Strips away assumptions and rebuilds the question from the ground up. Often the most valuable angle: "you're solving the wrong problem."

### Scout

Hunts for the upside everyone else is missing. What could be bigger? What adjacent opportunity is hiding in plain sight? What's being undervalued? Doesn't care about risk – cares about what happens if this works far better than expected.

### Stranger

Has zero context about you, your work, your history. Reacts only to what's on the page. Catches the curse of knowledge: terms you assume everyone knows, value you assume is obvious, framing that reads clear to you and confusing to anyone else.

### Operator

Only cares about Monday morning. Ignores theory and big-picture thinking. If an idea sounds brilliant but has no clear first step, the Operator says so. Every output ends with a concrete action.

### Why these five

Three deliberate tensions:
- Skeptic vs Scout – downside vs upside.
- Architect vs Operator – rethink vs ship.
- Stranger sits in the middle, keeping everyone honest with fresh eyes.


## Workflow

### 1. Greet and ask where to save

Output this verbatim, then stop and wait for the path answer. Picking a path is the consent to proceed – there is no separate "continue?" question.

```
Welcome to Devil's Advocates.

Multiple agents attack your thesis from different angles to find weak spots (fatal flaw, wrong framing, missed upside, outsider eyes, Monday-morning reality). They peer-review each other blind, then you get the verdict.

Five devils stand ready to break this idea apart:
- Skeptic   – hunts for the fatal flaw
- Architect – challenges the framing itself
- Scout     – digs for upside you're missing
- Stranger  – reacts with zero context
- Operator  – only cares about Monday-morning action

Heads up: a full run dispatches 11+ parallel sub-agents. Roughly 50-100k tokens and 2-5 minutes wall time (Warden runs on Opus, which skews to the upper end).

Where should I save the verdict?
- a) <project-relevant path 1>
- b) <project-relevant path 2>
- c) ./devils_verdict.md  (default fallback)
- d) Custom – give me a path
```

For path suggestions: prefer the canonical filename `devils_verdict.md` inside the most relevant folder. No date suffixes, no `_devils` suffixes – the folder gives context, the filename is fixed. If the user passed a specific document in the prompt, always set option `a)` to `<document_folder>/devils_verdict.md`. Otherwise scan the workspace for two topic-relevant folders – a project subfolder, a docs/notes folder, an ideas folder, or wherever similar verdicts already live. If nothing obvious surfaces, fall back to the current working directory.

If the user picks `d) Custom`, ask for the path. If they reply with anything other than a path choice (a question, a comment, a "wait" – anything), treat it as a request to discuss before proceeding. Don't assume consent.

### 2. Sharpen the question (sparring mode)

The five devils are only as good as the question they get. Before burning agent calls, run a short sparring round.

- Identify blind spots, hidden assumptions, missing constraints, conflated questions in the user's framing.
- Ask up to 5 clarifying questions – HARD CAP. Only the ones that genuinely change what the devils would argue about. Skip questions whose answers wouldn't move the verdict.
- **Always include one risk-elicitation question.** Ask the user what could go wrong, what they're worried about, or what they'd lose if the decision turns out badly. Their answer feeds the `Key Risks to Consider` block in step 4 – don't make the devils invent the risks from scratch.
- After 5 questions (or sooner if the question is sharp enough), force a choice: `Proceed` to dispatch, or `Stop` to abort entirely. No silent continuation past 5.
- The user can short-circuit at any point by typing **Proceed** or **Go**.
- After the round, restate the sharpened question in one paragraph and wait for confirmation before moving on.
- If the answers reveal the question is actually trivial, already answered, or not worth a council, say so and offer to skip the dispatch entirely (write nothing, commit nothing).

Aim for 95% confidence that the framing captures what the user actually wants tested. Better to ask one extra question now than to ship a generic verdict.

### 3. Scan workspace context (≤30 seconds)

The user's question is the tip of the iceberg. Glob and read the 2-3 files that would let the devils give grounded, specific arguments instead of generic ones.

Always check:

- Project context files if present (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`).
- Any user profile / identity / memory file the workspace surfaces (e.g. `user_profile.md`, `MEMORY.md`, `about.md`, or an equivalent memory folder). Read these only if they exist – do not require them.
- Any file the user explicitly referenced.

Conditionally check based on topic – Glob for files in the workspace that match the angle:

- Business / pricing / launches → business overview, stats, customer notes, prior launch postmortems.
- Blog / content → content strategy, style guide, audience notes, prior articles on the topic.
- Technical / architecture → relevant docs, decision records (ADRs), architectural notes.
- Personal / direction → notes about goals, identity, history.

Stop scanning once you have enough to brief the devils. More context is not better – signal beats volume.

### 4. Frame the question

Take the sharpened question plus what the scan surfaced and produce a single neutral framing block. Structure:

- The core decision or question (sharpened) as an opening paragraph – no header.
- `### Context` – key context the user gave, confirmed, or that workspace files surfaced (numbers, audience, constraints, prior results).
- `### Key Risks to Consider` – downside exposure as a bulleted list (one risk per bullet, tight phrasing). Source: the user's answer to the risk question in step 2 plus anything obvious surfaced by the scan. Don't bury risks in prose – the devils need to see them at a glance.

Use H3 headers (not `**bold:**` labels) for the subsections so they render as proper headings under `## The question` in the verdict file.

Don't insert an opinion. Don't lean. But give the devils enough to argue specifically rather than generally.

Save the framed block – it goes to every devil and into the verdict file.

### 5. Dispatch the devils (parallel)

Send all five Agent calls in a SINGLE message with five tool uses. Sequential dispatch wastes time and risks earlier responses bleeding into later ones.

For each devil, use:
- `subagent_type: general-purpose`
- (Default model is fine for the devils – Sonnet keeps the run cheap.)
- A self-contained brief built from the template in `## Devil briefs` below

### 6. Peer review (parallel, anonymized)

Collect all five responses. Assign them letters A-E by random shuffle (not by devil order – positional bias is real).

Send another five Agent calls in a single message. Each reviewer gets all five anonymized responses and answers the questions in `## Reviewer brief` below.

### 7. Warden synthesizes

One final Agent call. **Use `model: opus`** – synthesis is the highest-stakes step and Opus's depth shows here. The Warden gets:
- The framed question
- All five devil responses (de-anonymized – names restored)
- All five peer reviews
- The brief in `## Warden brief` below

The brief explicitly asks the Warden to think deeply, not truncate, and flag low-signal runs (where the devils gave generic, interchangeable answers) instead of producing a confident verdict over weak inputs.

The Warden returns the verdict body in markdown.

### 8. Pre-write checks

Before calling Write:
- **Path validation**: confirm the parent folder exists and is writable. If the folder is missing, create it (`mkdir -p`) – don't fail.
- **Existing-file check**: if a file already exists at the chosen path, ask:
	- `a)` Append a new dated section to the existing file (preserves prior runs on the same topic)
	- `b)` Write as `<name>_v2.md` (or `_v3.md`, etc., picking the next free number)
	- `c)` Overwrite (destroys the prior verdict – confirm explicitly)

### 9. Write the verdict file

Use the Write tool with the structure in `## Verdict file structure` below. Frontmatter `created` = today; `updated` = today; `tags: [devils, decision]`. If appending (option `a` above), use Edit instead and add a new `## Run – {date}` section under the existing content.

### 10. Brief in-chat summary

After writing, output a SHORT chat summary:
- A one-line pointer to the file (markdown link).
- The recommendation (1-2 lines).
- The first move (1 line).

Nothing else. The full verdict lives in the file. The user reads it in their editor of choice.


## Devil briefs

Each brief follows this template – swap the role description and the first-line label.

```
You are the {DEVIL_NAME} on a panel of five devil's advocates.

Your angle: {ROLE_DESCRIPTION}

A decision has been brought to the panel:

---
{FRAMED_QUESTION}
---
Argue from your angle. Be direct and specific. Do not hedge. Do not try
to be balanced. The other four devils cover the angles you aren't covering.
Lean fully into your perspective – if you see a fatal flaw, name it. If
you see massive upside, name it.

House style:
- N-dash (–) with spaces, never m-dash. No emojis. No AI slop words.
- 150-300 words. No preamble. Open with your strongest point.
- Plain paragraphs and short bullet lists. No headers.
```

Role descriptions:

- **Skeptic** – Hunt for the fatal flaw. Assume there is one. The idea looks fine on the surface; your job is to find the hole. Surface the question the user is avoiding.
- **Architect** – Ignore the surface question. Ask what the user is really trying to achieve. Strip assumptions. Rebuild the problem. If the framing is wrong, say "you're asking the wrong question" and explain what the right question is.
- **Scout** – Hunt for upside the others miss. What's the ceiling here if this works? What adjacent opportunity is hiding? What's being undervalued? Risk is not your problem – the Skeptic handles that.
- **Stranger** – You have zero context about this person, their work, their audience, or their history. React only to what's in the framing block. Flag jargon. Flag assumed value. If a term means nothing to you, say so – chances are it means nothing to outsiders too.
- **Operator** – Only one question matters: what does the user do Monday morning? Ignore theory and strategy. Look at every idea through "what's the smallest concrete first step?" If there isn't one, say the idea isn't shippable yet and propose the validation that makes it shippable.


## Reviewer brief

```
You are reviewing the work of five devil's advocates. They independently
attacked this question:

---
{FRAMED_QUESTION}
---

Here are their anonymized arguments:

**Response A:**
{response_a}

**Response B:**
{response_b}

**Response C:**
{response_c}

**Response D:**
{response_d}

**Response E:**
{response_e}

Answer all three questions. Reference responses by letter. Be direct.

1) Which response is the strongest and why?
2) Which response has the biggest blind spot, and what is it missing?
3) What did ALL FIVE responses miss that the panel should consider?

House style:
- N-dash (–) with spaces, never m-dash. No emojis. No AI slop words.
- Under 200 words. No preamble.
```


## Warden brief

```
You are the Warden. Five devil's advocates argued this question, then
peer-reviewed each other anonymously. The devils answer to you. Your
job: synthesize their work into a verdict that gives the user clarity
they could not get from any single perspective.

Think deeply. Take the work seriously – this is the highest-stakes
step. Don't truncate to be brief; verdict length should reflect what
the synthesis actually requires.

LOW-SIGNAL CHECK – do this first, before anything else. If the five
devils gave generic, interchangeable, or evasive arguments – the kind
that could apply to almost any business decision – the run failed at
the framing stage. In that case, return ONLY this:

  ## Low-signal verdict

  The devils produced generic arguments rather than ones grounded in
  this specific question. Recommend re-running with a sharper question.
  What was missing: [name 1-2 specifics that would have made the
  arguments concrete – e.g. "actual numbers", "named audience",
  "concrete options instead of vague directions"].

Do not produce a confident verdict over weak inputs. Honest
"insufficient signal" beats confident slop.

The framed question:

---
{FRAMED_QUESTION}
---

DEVIL ARGUMENTS (de-anonymized):

**Skeptic:**
{response}

**Architect:**
{response}

**Scout:**
{response}

**Stranger:**
{response}

**Operator:**
{response}

PEER REVIEWS:
{all five reviews}

Produce the verdict using this exact section structure. Be direct. Do not
hedge. You may disagree with the majority if the minority's reasoning is
stronger – say so and explain why.

## The outcome

### Quick Recommendation #TLDR

[1-2 tight sentences: the call, not the reasoning. This is the section
the user reads first and may be the only section they read – make it
stand on its own. Do NOT include the first step here; that is its own
H3 right below.]

### Your first step #TODAY

[ONE concrete next step. Not a list. One thing the user does first.
Personal and actionable – tell the user what to do, not what should
happen.]

## Where the devils agree

[Points multiple devils converged on independently. High-confidence
signals.]

## Where the devils clash

[Genuine disagreements. Use H3 subheaders for each clash topic – not
bold labels. Each `### subheader` introduces one disagreement, then
prose presents both sides and explains why reasonable devils disagree.]

## Blind spots the devils caught

[Things only surfaced through peer review – things one devil missed
that another flagged.]

## If you pull this off #YMMV

[ONE short paragraph, ~600 characters max. Paint the success scenario
grounded in whatever user profile / identity context the workspace
surfaced (if any) AND the verdict you just wrote above. Not generic
motivation – the win condition implied by the recommendation, rendered
concrete: named outcomes, named timelines, named identity, the specific
thing that compounds. Open with "If you pull this off, ...". Direct, no
slop, no exclamation marks, no future-perfect grandiosity. One
paragraph, n-dashes with spaces.]

## Full Recommendation

[The full reasoning behind the Quick Recommendation. Why this verdict, what
trade-offs it accepts, what it explicitly rejects. If the verdict
proposes multiple experiments or actions, present them as a bulleted
list – not as numbered prose paragraphs ("First, ... Second, ...").
One bullet per action, each bullet a tight paragraph if reasoning is
needed.]

House style:
- N-dash (–) with spaces, never m-dash. No emojis. No AI slop words.
- Plain markdown only. No HTML. No tables unless data demands one.
- Tight prose. Short paragraphs. Cut filler.
```


## Verdict file structure

The file written by step 9 has this exact shape:

```markdown
---
title: Devils' Verdict – {topic}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [devils, decision]
---
# Devils' Verdict

## The question

### {topic}

{framed question opening paragraph}

### Context

{context paragraph}

### Key Risks to Consider

- {risk 1}
- {risk 2}
- {risk 3}

{Warden verdict body – outcome (with Quick Recommendation + Your first step as H3s), agree, clash, blind spots, if you pull this off, full recommendation}

## Full transcript

### Skeptic

> {response paragraph 1}
>
> {response paragraph 2}

### Architect

> {response}

### Scout #WORTHREADING

> {response}

### Stranger

> {response}

### Operator

> {response}
```

The H1 is generic (`# Devils' Verdict`) – the topic lives in the frontmatter `title` and as an H3 under `## The question`. This way the H1 matches the filename (`devils_verdict.md`), and any editor that surfaces frontmatter (Obsidian, Logseq, Foam, etc.) still shows the topic in tabs and search.

**Blockquote spacing.** When a devil's response has multiple paragraphs, separate them with a blank quote line (`>`) – not a bare blank line, which would close the blockquote. Single-paragraph responses stay as one quoted block.

Peer reviews are not written to the file – they are an internal stage that fed the Warden. The reasoning surfaces in the verdict body itself.

When appending to an existing file (option `a` in step 8), wrap the new run in a `## Run – {YYYY-MM-DD}` heading and use the same structure inside it.


## Rules

- Always run the Sharpen round before dispatching. Hard cap: 5 questions. User can short-circuit with "Proceed" or "Go".
- Always dispatch the five devils in parallel. Single message, five tool calls.
- Always anonymize for peer review. Letters A-E, randomly shuffled.
- Always run the Warden on `model: opus`. Devils and reviewers run on default (Sonnet).
- The Warden can override the majority. Reasoning beats vote count.
- The Warden must flag low-signal runs instead of producing confident slop.
- Pre-write check: validate path, detect existing files, ask before overwriting.
- Don't run for trivia. If the answer is one Google away, just answer it.
- Pure markdown output. No HTML. No charts. The user reads the file in their editor of choice.
- Always write the verdict to a file. Never dump the full output into chat.

## Examples

Pressure-test a pricing decision with real stakes:

```bash
/devils should I launch a $97 workshop or build a $497 course
```

Stress-test a positioning choice between concrete options:

```bash
/devils which of these three positioning angles is strongest
```

Red-team a pivot you are uncertain about:

```bash
/devils I'm thinking of pivoting from consulting to a SaaS product, am I crazy
```

