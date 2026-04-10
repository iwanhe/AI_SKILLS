---
name: deployment
description: "Oracle APEX deployment process — environment strategy, Git branching, developer workflow, release and hotfix procedures, QA checks, CI/CD automation, and ADT tooling. Use this skill whenever planning, reviewing, or executing deployments, setting up CI/CD pipelines, configuring Git branching strategy, preparing patches, reviewing pull requests against deployment standards, onboarding developers to the deployment process, or discussing release management for Oracle APEX projects. Triggers: deployment, release, hotfix, patch, CI/CD, branching strategy, pull request review, PR checklist, deployment process, release management, environment sync, Git workflow APEX, deployment log, patch script, squash merge, rebase, feature branch."
---

# Oracle APEX Deployment Process

This skill defines the complete deployment process for Oracle APEX projects. It covers environment strategy, version control, development workflow, release and hotfix procedures, QA checks, CI/CD automation, and tooling.

The full process document is in `references/process.md`. Read it when you need the complete details. Below is a summary of each section and guidance on when to consult it.

## When to use this skill

- **Reviewing a pull request** — check the PR Approval Criteria (section 3) for the full checklist.
- **Preparing a patch** — follow the developer task workflow (section 3, steps 6–7) and the patch folder convention.
- **Setting up or reviewing CI/CD** — consult section 7 for branch protection, Git hooks, CI pipeline steps, and deployment process.
- **Planning a release** — follow the release workflow (section 4) for branching, tagging, and merge steps.
- **Handling a production issue** — follow the hotfix workflow (section 5) for the urgent fix process.
- **Onboarding a developer** — the full document serves as the onboarding reference.
- **Checking QA requirements** — section 6 covers automated checks, manual verification, and client confirmation.

## Key principles

- **Two environments minimum**: DEV (`dev` branch) and PROD (`main` branch). No skipping environments.
- **Feature-to-environment merges only**: never merge one environment branch into another. Each task stays independently deployable.
- **Squash merge** into environment branches to prevent false conflicts and keep history clean.
- **Rebase** feature branches onto `dev` or `main` to stay current — never merge the other direction.
- **One patch per task**: never combine multiple tasks into one script.
- **Per-task acceptance criteria**: defined before work starts, verified by developer, reviewer, and QA.
- **Deploy tasks individually** when possible for short feedback loops. Group into releases only when needed.

## Developer task workflow (summary)

1. Pick up a task — verify acceptance criteria exist.
2. Create a feature branch from `dev`: `feat/{task_id}/{description}`.
3. Write unit tests before implementation (85% coverage threshold).
4. Implement changes.
5. Export and commit regularly (at least daily, even work in progress).
6. Prepare the patch with `adt patch` — one patch per task.
7. Verify the patch on DEV.
8. Rebase onto `main`.
9. Self-review: acceptance criteria, formatting, security, performance.
10. Create a pull request.

For the full details on each step, read `references/process.md` section 3.

## PR approval checklist (summary)

- Git diff is correct and complete.
- Acceptance criteria fulfilled.
- Code formatting, error handling, and security standards met.
- No hardcoded credentials, no SQL injection risks.
- Performance reviewed.
- Unit tests pass with 85% coverage.
- Patch script is correct, deployment log is clean.
- APEX exports (split, readable, embedded code report) present.

For the full checklist, read `references/process.md` section 3 (Pull Request Approval Criteria).

## Deployment process (summary)

1. Connect securely to the target instance.
2. Execute patch scripts in A–Z order.
3. Run post-deployment checks (invalid objects, object counts, APEX stats).
4. Store deployment log with `[SUCCESS]` or `[ERROR]` suffix.
5. Archive successful patches from `patches/` to `patches_done/`.
6. If release branch: merge into `main`.
7. On failure: notify all involved, stop subsequent patches.

For the full details, read `references/process.md` section 7.

## Task board statuses

**Backlog** → **Todo** → **In Progress** → **In Review** → **Done** → **Delivered**

Only Todo, In Progress, In Review, and Done are visible on the board. Swimlanes per developer.

## Related skills

- `adt` — ADT command reference and flags
- `apex-qa` — APEX application quality standards
- `plsql-format` — PL/SQL formatting standards
- `plsql-code-quality` — PL/SQL code quality guidelines
- `data-model` — Database design standards
- `apex-rest` — REST service standards
