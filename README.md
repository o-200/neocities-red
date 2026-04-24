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

- **CLI** with explicit command help (`neocities-red help <command>`)
- **Parallel uploads** (up to 5 concurrent workers)
- **Smart diffing** (only upload what changed)
- **Automatic retries** (handles flaky Neocities API / SSL issues)
- **Recursive uploads** out of the box
- **SSG-friendly** (Jekyll, Hugo, Eleventy, etc.)
- **Namespaced services** grouped by domain (`file/`, `site/`, `common/`)

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
neocities-red help
neocities-red help push
```

---

## CLI Commands

```text
push      Recursively upload a local directory to your site
upload    Upload individual files/folders to your site
delete    Delete remote files
diff      Compare local directory with remote
list      List remote files
info      Show site info
pull      Download latest remote files
logout    Remove stored API key from config
version   Print gem version
pizza     Easter egg
```

### `push` options

| Flag | Description |
| --- | --- |
| `--no-gitignore` | Ignore `.gitignore` filtering and upload matching files |
| `--ignore-dotfiles` | Skip dotfiles/dot-directories |
| `-e`, `--exclude` | Exclude file/directory paths |
| `--dry-run` | Show intended actions without mutating remote |
| `--optimized` | Skip files that already match remote hash |
| `--prune` | Delete remote files that do not exist locally |

Examples:

```bash
neocities-red push .
neocities-red push --optimized --ignore-dotfiles .
neocities-red push -e node_modules -e .git .
neocities-red diff . -e secret.txt
```

---

## Library Usage

### Basic Client

```ruby
require 'neocities-red'

client = NeocitiesRed::Client.new(api_key: 'YOUR_API_KEY')

client.upload(local_path, remote_path)
client.delete(remote_path)
client.list(remote_path)
client.info(sitename)
```

---

### Advanced: Services

```ruby
client = NeocitiesRed::Client.new(
  sitename: 'o200',
  password: 'secret'
)

service = NeocitiesRed::Services::File::List.new(
  client,
  '.',
  true
)

files = service.show
```

Current service namespaces:

- `NeocitiesRed::Services::File` (`Uploader`, `FolderUploader`, `List`, `Remover`)
- `NeocitiesRed::Services::Site` (`Pusher`, `Differencer`, `Exporter`, `Informer`)
- `NeocitiesRed::Services::Common` (`Pizza`)

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
