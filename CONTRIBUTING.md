# Contributing

Thanks for your interest in contributing! 🎉  
This document explains how to contribute to **neocities-red**.

> By participating in this project, you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Ways to contribute

You can help in many ways:

- **Report bugs** (repro steps, logs, screenshots)
- **Request features** (problem statement + proposed solution)
- **Improve docs** (examples, tutorials)
- **Contribute code** (bug fixes, features, refactors)
- **Review pull requests** (testing, feedback)

If you’re not sure where to start, check **Issues** labeled:
- `good first issue`
- `help wanted`
- `documentation`

---

## Before you start

### Check for existing work
Please search existing **issues** and **pull requests** before opening a new one.

### Discuss bigger changes
For substantial changes (new features, architecture, major refactors), open an issue first to align on direction.

---

## Project setup

### Prerequisites
- **[Language/Runtime]**: Ruby 4.*

### Install
```bash
# clone
git clone https://github.com/[OWNER]/[REPO].git
cd [REPO]

# install dependencies
bundle install

# Run locally
bin/neocities-red
bin/neocities-red push .

# Run tests
rspec

# Linter
rubocop
```

## Pull request guidelines

### PR title

Use a clear title, ideally Conventional Commits style:

- `feat: …`
- `fix: …`
- `docs: …`

### PR description checklist

Include:

- What changed and why
- How to test the change
- Screenshots/gifs for UI changes
- Any breaking changes

### Keep PRs focused

Smaller PRs are easier to review and merge. If you’re changing multiple unrelated things, split into separate PRs.
