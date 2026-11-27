# Conventions

## Branches

| Branch | Lifetime | Purpose |
|---|---|---|
| `main` | Permanent, **protected** | Production code only. Every release is a merge plus a tag (`v1.0.0`) |
| `develop` | Permanent, **protected** | Integration branch and the GitHub default branch |
| `release/x.y.z` | Short | Cut from `develop` for review/TestFlight, deleted after merging. Urgent fixes after a release are also handled this way (`release/1.0.1` from `main`) |

Protected means nobody pushes to `develop` or `main` directly, including the repo owner. They only change through merged pull requests whose CI checks have passed.

Work branches start from `develop`:

| Prefix | For | Example |
|---|---|---|
| `feature/` | New functionality, including changes to existing features | `feature/onboarding` |
| `bugfix/` | Bug fixes | `bugfix/timer-not-firing` |
| `refactor/` | Restructuring code without changing behaviour | `refactor/session-state-machine` |
| `chore/` | Setup, CI, configuration, dependencies, tooling | `chore/github-actions` |
| `docs/` | README, architecture docs, CLAUDE.md | `docs/data-sync` |

Use lowercase names with hyphens.

## Workflow

### Features (and every other work branch)
1. Branch off `develop` and commit as often as you like.
2. **Review locally** with Claude Code's `/code-review`, comparing the branch with `develop`. Fix what it finds.
3. Push and open a pull request to `develop`. **Its title becomes the squashed commit message**, so it must follow the commit convention below.
4. CI runs on the pull request. When it's green: **Squash and merge**, then delete the branch.

### Releases
1. Cut `release/x.y.z` from `develop`, then bump the version and test.
2. Open a pull request to `main`. When CI is green: **Create a merge commit**. Never squash here, because `main` and `develop` would diverge.
3. Tag the merge commit on `main`: `vx.y.z`.
4. Bring it back with a pull request from `main` to `develop`, also with a merge commit.

## Commits

[Conventional Commits](https://www.conventionalcommits.org) format, with types matching the branch prefixes:

```
<type>(<optional scope>): <summary>
```

```
feature(onboarding): add mode selection screen
bugfix(timer): stop playback when timer fires in background
refactor(session): extract state machine into Domain package
chore(ci): add build and test workflow
docs: describe data sync design
```

- Types: `feature`, `bugfix`, `refactor`, `chore`, `docs`. We don't use `feat`/`fix`, so any future changelog or commit-lint tool needs configuring for these types.
- Lowercase, imperative mood ("add", not "added"), no trailing period.
- The same rules apply to pull request titles.

## Git hooks

Local hooks live in `.githooks/`. Enable them once per clone:

```bash
git config core.hooksPath .githooks
```

**They only warn and never block** a commit or push.

| Hook | What it does |
|---|---|
| `pre-commit` | Lints staged Swift files with swift-format |
| `prepare-commit-msg` | Pre-fills `type(scope): ` from the branch name. The scope is the part before the first hyphen: `bugfix/timer-not-firing` → `bugfix(timer): `. It only appears for a plain `git commit` in the terminal or an editor; GUI clients like GitKraken usually ignore it |
| `commit-msg` | Checks the message against the commit convention |
| `pre-push` | Checks the branch name against the prefixes above |

The hooks can't see squash commits created on GitHub, so pull request titles have to be checked by eye.

## Code style

- Formatting and linting with **swift-format** (included in the Xcode toolchain). The config lives in `.swift-format`: 4-space indentation, 120-character lines.
- Format: `swift format --in-place --recursive --parallel NightFade NightFadeWatch Packages`
- Lint, as run in CI: `swift format lint --strict --recursive --parallel NightFade NightFadeWatch Packages`
- In Xcode: Editor → Structure → Format File with 'swift-format'.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs **only on pull requests** to `develop` and `main`, and on every new push to an open pull request. There's no run after merging, because the merged code has already passed. It can also be started by hand from the Actions tab.

1. swift-format lint
2. `Domain` package tests
3. iOS build, including the embedded Watch app
4. watchOS build

Simulator builds don't need code signing. Xcode Cloud will be added later for TestFlight and App Store releases.
