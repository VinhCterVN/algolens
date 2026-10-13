# Commit Guide

## Message Format

This repository has no commits yet. Adopt the following convention for new commits:

```text
<type>(<scope>): <imperative summary>
```

Use a lowercase type and an optional scope. Keep the subject near 72 characters or fewer, omit the final period, and describe one focused change.

## Types and Scopes

| Type | Use for |
| --- | --- |
| `feat` | New user-facing functionality |
| `fix` | Correcting a bug |
| `refactor` | Restructuring code while preserving behavior |
| `test` | Adding or updating tests |
| `docs` | Documentation changes |
| `style` | Formatting changes without behavior changes |
| `build` | Dependencies, Flutter assets, or Android build configuration |
| `chore` | Repository maintenance and tooling |

Use feature scopes such as `canvas`, or areas such as `app` and `android`.

```text
feat(canvas): Add zoom controls
fix(canvas): Center the grid on launch
refactor(canvas): Extract the grid painter
test(canvas): Verify drag gestures move the viewport
docs: Document feature folder conventions
build(android): Configure release signing
```

## Bodies and Breaking Changes

For a nontrivial change, leave a blank line after the subject and explain why it is needed, relevant tradeoffs, and validation performed. Reference an issue with `Refs #123`; use `Closes #123` only when the change resolves it.

Mark an incompatible change with `!` after the type or scope and a `BREAKING CHANGE:` footer describing the required migration.

## Before Committing

Run these commands from the project root:

```sh
dart format lib test
flutter analyze
flutter test
git status --short
git diff
git diff --cached
```

Review both staged and unstaged changes. Stage only intended files, for example `git add lib/features/canvas test/features/canvas`. Keep unrelated changes in separate commits. Exclude generated build output, credentials, and local SDK paths. Do not overwrite another contributor's staged work.

## Pull Requests

Summarize the behavior changed, link relevant issues, and record the checks run and their results. Include screenshots or a short recording for visible UI changes. Explain any migration or follow-up work.
