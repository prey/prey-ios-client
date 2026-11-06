---
name: ship-release
description: Use when a change in the Prey iOS client is ready to ship - opening the PR on GitHub, bumping the app version, writing App Store release notes, or uploading a build to App Store Connect / TestFlight. Invoke with an optional bump level (patch | minor | major) or an explicit version like 2.3.0.
---

# Ship a Prey iOS release

Two phases, because a human must review and merge in between:

1. **PR phase** — branch, commit, bump version, build, push, open PR with release notes (EN + ES).
2. **Upload phase** — after the PR is merged: archive `master` and upload to App Store Connect.

If the PR for this change is already merged, skip to the Upload phase.

## PR phase

### 1. Scope the change
- `git status --short` and `git diff`. Commit **only** files that belong to this change. The working tree usually holds unrelated edits (xcuserstate, `LocationPushService` submodule pointer, scratch docs) — never `git add -A` / `git add .`. Ask if ownership of a file is unclear.
- `gh auth status` must show the `repo` scope.
- Know the user-visible symptom before writing anything (branch slug, PR, release notes). If the conversation and diff don't make it clear, ask.
- **Check for an unreleased version bump:** `gh pr list --base master --state open --json number,title,headRefName`. If an open PR already bumps the version (title starts with `X.Y.Z`), don't bump again — `master` is behind it and a new bump would collide. Ask the user: add this change to that PR's branch (recommended, no extra bump), or wait until it merges.

### 2. Branch
```bash
git fetch -q origin
git switch -c <type>/<kebab-slug> --no-track origin/master
```
- `<type>` must be one of `feat|fix|docs|style|refactor|perf|test|chore`. `.githooks/pre-commit` checks the *current* branch at commit time, so committing on `master` is blocked too.
- `--no-track` matters: without it the branch tracks `origin/master` and a bare `git push` targets master.
- Uncommitted changes carry over to the new branch; that is fine, just don't stage them.
- If the user is already on a feature branch with the commits, stay on it.

### 3. Bump the version (edit only, commit in step 5)
Current version: `grep -m1 MARKETING_VERSION Prey.xcodeproj/project.pbxproj`.

| Arg | 2.2.13 → |
|---|---|
| none / `patch` | 2.2.14 |
| `minor` | 2.3.0 |
| `major` | 3.0.0 |
| explicit `X.Y.Z` | X.Y.Z |

Rules:
- Only the configs **at the current app version** change (4 of them: Prey + LocationPushService, Debug + Release). Configs at other versions (e.g. `2.1.11`, the notify/test targets) are left alone.
- **Build number resets to `1`** on a new marketing version (repo convention; App Store only requires uniqueness per version).
- Match on the version string, never on line numbers:
```bash
f=Prey.xcodeproj/project.pbxproj; old=2.2.13; new=2.2.14
build=$(grep -m1 CURRENT_PROJECT_VERSION "$f" | tr -dc 0-9)
# Change build only inside configs that carry $old: those blocks list CURRENT_PROJECT_VERSION before MARKETING_VERSION.
perl -0pi -e "s/CURRENT_PROJECT_VERSION = $build;((?:(?!CURRENT_PROJECT_VERSION)[\s\S])*?MARKETING_VERSION = \Q$old\E;)/CURRENT_PROJECT_VERSION = 1;\$1/g; s/MARKETING_VERSION = \Q$old\E;/MARKETING_VERSION = $new;/g" "$f"
git diff -- "$f" | grep '^[-+]\s'   # expect 4× MARKETING (+ 4× CURRENT_PROJECT unless build was already 1), nothing else
```

### 4. Verify (before committing, so a broken build doesn't mean rewriting commits)
```bash
xcodebuild -workspace Prey.xcworkspace -scheme Prey -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$TMPDIR/prey-dd" build CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|\*\* BUILD" | tail -5
```
Always pass `-derivedDataPath`: sharing Xcode's DerivedData locks `build.db` and breaks the user's Xcode build ("database is locked").
Must print `** BUILD SUCCEEDED **`. SourceKit's "No such module 'UIKit'" diagnostic is an indexer artifact — ignore it; trust `xcodebuild`.

### 5. Commit — two commits
1. The change, staged by explicit path. Follow `AGENTS.md`: imperative subject ≤72 chars, body explains the *why*.
2. The bump: `git add Prey.xcodeproj/project.pbxproj`, subject `X.Y.Z` (just the version, like previous releases).

### 6. Push and open the PR
```bash
git push -u origin <branch>      # pre-push hook runs SwiftLint; errors block the push
gh pr create --base master --title "X.Y.Z: <summary>" --body-file <file>
```
PR body sections: **Problem**, **Fix**, **Linked issue** (if any), **Screenshots** (UI changes only), **Version** (`Bumps to **X.Y.Z (build 1)**.`), **Testing** (checkboxes; tick only what was actually run. Device tests: tick the steps the user confirmed; if they only said "tested on a device", write one ticked line `Tested on a real device` rather than inventing repro steps), **Release notes** (below).

**Keep the PR title and body about the change itself: no tool attributions or footers.** Commit messages follow the session's normal commit rules.

Then `gh pr checks <n> --watch` and report the result.

### 7. Release notes (in the PR body and in your reply)
Two blocks, ready to paste into App Store Connect → *What's New in This Version* (use whichever Spanish locale the app page lists):

```markdown
**English (U.S.)**
- Installing the device profile from Safari no longer gets stuck in a "too many redirects" loop. Set it up once and get back to work.

**Español (México)**
- Instalar el perfil del dispositivo desde Safari ya no se queda atrapado en un bucle de "demasiadas redirecciones". Lo configuras una vez y listo.
```
- Written for end users: what they notice, not what the code does. No class names, states, HTTP codes, or PR numbers.
- Follow **Copy & Tone** in `AGENTS.md`: helpful IT buddy, empathy over hype. Lead with what's better for the user, keep it to one or two short sentences per bullet, a light touch of wit at most. Never "revolutionary", "game-changer", "best-in-class".
- One bullet per user-visible change since the last release. The last release is the latest squash commit whose title starts with `X.Y.Z (` on master, usually `X.Y.Z (#N)` but sometimes `X.Y.Z (build): summary` (tags are inconsistent, don't use them):
  `last=$(git log -1 --format=%h -E --grep='^[0-9]+\.[0-9]+\.[0-9]+ \(' origin/master); git log --oneline $last..HEAD`
- Internal-only changes → "Performance and stability improvements." / "Mejoras de rendimiento y estabilidad."
- Spanish: neutral Latin American, `tú`/impersonal or `nosotros`; no voseo (`podés`, `tenés`), no Spain-only forms (`vosotros`). Mirror the English meaning, don't translate word by word.
- Under 4000 characters each (App Store limit).

**Stop here.** Tell the user the PR needs a review and merge. Merge convention: squash, title `X.Y.Z (#N)`. GitHub pre-fills the PR title instead, so remind them to change it.

## Upload phase (after merge)

Confirm with the user before uploading — an upload consumes the build number permanently.

```bash
git fetch -q origin && git switch --detach origin/master
grep -m1 MARKETING_VERSION Prey.xcodeproj/project.pbxproj   # must be the released version
out="$TMPDIR/prey-X.Y.Z"
xcodebuild -workspace Prey.xcworkspace -scheme Prey -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$out/Prey.xcarchive" -derivedDataPath "$out/dd" \
  -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath "$out/Prey.xcarchive" \
  -exportOptionsPlist .claude/skills/ship-release/ExportOptions.plist \
  -exportPath "$out/export" -allowProvisioningUpdates
git switch -    # back to the previous branch
```
- Signing uses the Apple ID logged in under Xcode → Settings → Accounts (team `M2J57RQ35B`). If signing fails, ask the user to sign in there — don't try to fix certificates.
- "bundle version must be higher" / duplicate build → bump `CURRENT_PROJECT_VERSION` to the next number in a follow-up PR; never re-upload the same number.

Then give the user the remaining manual steps: wait for the build to finish processing in App Store Connect → TestFlight smoke test (for fixes, re-run the original repro on the TestFlight build) → paste the release notes → submit for review.

## Common mistakes

| Mistake | Fix |
|---|---|
| `git add -A` picks up xcuserstate / submodule / unrelated edits | Stage explicit paths only |
| Branch tracks `origin/master` | `--no-track`; push with `-u origin <branch>` |
| Bumping while another release PR is open | Check open PRs first; add to that PR instead |
| Bumping the `2.1.11` configs too | Only replace the current version string |
| Build number left at the old version's value | Reset to `1` for a new marketing version |
| zsh eats `$c:P...` in `"$c:Prey..."` (`:P` is a modifier) | Use `"${c}:path"` |
| Ticking device-test boxes that weren't run | Tick only after the user confirms |
| Release notes describe code ("301 with empty Location") | Describe what the user sees |
