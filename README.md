![CI](https://img.shields.io/github/actions/workflow/status/o-200/neocities-red/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/neocities-red?style=for-the-badge&logo=rubygems&logoColor=white)](https://rubygems.org/gems/neocities-red)
[![Ruby](https://img.shields.io/badge/Ruby-3.4%2B%20%7C%204.0-CC342D?style=for-the-badge&logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos%20%7C%20windows-blue?style=for-the-badge)]()
[![License](https://img.shields.io/github/license/o-200/neocities-red?style=for-the-badge)](https://github.com/o-200/neocities-red/blob/main/LICENSE)
[![Made with Love](https://img.shields.io/badge/Made%20with-%E2%9D%A4-red?style=for-the-badge)]()

# 🟥 Neocities Red

> A modern Neocities CLI

A **refactored and extended fork** of the official https://github.com/neocities/neocities-ruby

Built for performance, reliability, and real-world workflows (especially static site generators).

---

## ✨ Key Features

- **Parallel uploads** (3–5 concurrent workers)
- **Smart diffing** (only upload what changed)
- **Automatic retries** (handles flaky Neocities API / SSL issues)
- **Recursive uploads** out of the box
- **SSG-friendly** (Jekyll, Hugo, Eleventy, etc.)
- **Clean, extensible architecture**

---

## Installation

### Requirements

- **Ruby 3.4+** (tested, supports 4.x)

Not a programmer?

- Install Ruby here - https://www.ruby-lang.org/en/
- For Windows you should have installed MSYS2 and MINGW

Using version managers:

- `mise`
- `asdf`

---

### Install

```bash
gem install neocities-red
```

---

## Quick Start

```bash
neocities-red
```

---

## What's New

### 0. Full Refactor

- Modernized dependencies
- Improved Ruby compatibility (3.4 → 4.x)
- Cleaner architecture for future features

---

### 1. `upload` — Parallel & Recursive

- Multi-threaded (3–5 concurrent uploads)
- Fully recursive
- Rewritten upload pipeline

---

### 2. `push`

Designed for static site workflows.

| Flag                | Description                       |
| ------------------- | --------------------------------- |
| `--optimized`       | Upload only changed/missing files |
| `--ignore-dotfiles` | Skip `.git`, `.env`, etc.         |
| `-e <folder>`       | Ignore folder recursively         |

#### Examples

```bash
neocities push --optimized --ignore-dotfiles .
neocities push -e node_modules -e .git .
```

---

### 3. `diff` — Local vs Remote

Preview changes before uploading:

```bash
neocities diff .
```

---

### 4. Built-in Retries

Handles:

- SSL errors
- timeouts
- unstable Neocities API

No more broken deploys due to transient failures.

---

## Library Usage

### Basic Client

```ruby
require 'neocities-red'

client = Neocities::Client.new(api_key: 'YOUR_API_KEY')

client.upload(local_path, remote_path)
client.delete(remote_path)
client.list(remote_path)
client.info(sitename)
client.push(local_path)
```

---

### Advanced: Services

```ruby
client = Neocities::Client.new(
  sitename: 'o200',
  password: 'secret'
)

service = Neocities::Services::FileList.new(
  client,
  path: '.',
  detail: true
)

files = service.show
```

---

## Contributing

1. Check existing issues
2. Comment: "I'll take this"
3. Fork the repo
4. Create a feature branch
5. Implement + test
6. Open a PR

---

## License

MIT — see LICENSE

---

## Acknowledgements

Built for the Neocities community.
