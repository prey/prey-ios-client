# Git Workflow: develop-trunk with GitHub protections

## Context and goal
We need a simple workflow where all work merges into `develop`, and only `develop` is merged into `main`. Releases happen when something is ready, and CI must validate merges. The team is a single developer, so approvals are not required.

## Proposed workflow (recommended)
Trunk-based with `develop` as the trunk branch:
- Create short-lived branches from `develop`: `feature/*`, `fix/*`, `chore/*`, `docs/*`.
- Open PRs from those branches into `develop`.
- No direct pushes to `develop` or `main`.
- When ready to release, open a PR `develop` -> `main`.
- Merge `develop` into `main`, then tag a release (`vX.Y.Z`).

This keeps `main` as the latest released state and `develop` as the integration branch.

## Branch protection rules (GitHub)
For `develop`:
- Require a pull request before merging.
- Require status checks to pass (CI).
- Require branch to be up to date before merging.
- Block force-push and deletion.

For `main`:
- Require a pull request before merging.
- Require status checks to pass (CI).
- (Optional) Require a tag or GitHub Release on merge.
- Block force-push and deletion.

## CI requirements
Minimum checks (blocking):
- Build.
- Tests (unit/integration if present).
- Lint/format (if configured).

If CI is slow, keep the blocking checks minimal and move extended checks to nightly.

## PR checklist (single-developer)
- PR is small and focused.
- CI passes.
- Description explains what changed and why.
- UI changes include evidence (screenshots or notes).
- No intentional breaking changes without a note.

## Implementation notes
Recommended files:
- `PULL_REQUEST_TEMPLATE.md` with the checklist above.
- `CONTRIBUTING.md` summarizing the workflow in ~10 lines.

## Success criteria
- All merges to `develop` and `main` go through PRs.
- CI is required and blocks merges when failing.
- Releases are created only from `main` via `develop`.
