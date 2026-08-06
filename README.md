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
- **Incremental `pull`** — skips files unchanged since your last pull
- **`.gitignore`-aware `push`** — respects your ignore rules by default

---

## Requirements

- **Ruby 3.4+** (CI-tested against 3.4, 3.5, and 4.0 on Linux, macOS, Windows, and FreeBSD)

Not a programmer?

- Install Ruby here - https://www.ruby-lang.org/en/
- For Windows you should have installed MSYS2 and MINGW

---

## Installation

```bash
gem install neocities-red
```

---

## Quick Start

```bash
neocities-red help
neocities-red help push
```

On first authenticated command you'll be prompted for your sitename/username and
password — the resulting API key is stored locally for future runs.

```bash
neocities-red push .
```

---

## Authentication

The CLI resolves credentials in this order:

1. **`--api-key` flag** — `neocities-red --api-key <key> push .`
2. **`NEOCITIES_API_KEY` environment variable**
3. **Stored config** — the API key saved by a previous interactive login
4. **Interactive login** — prompts for sitename/username and password

For non-interactive logins you can also set:

| Variable | Purpose |
| --- | --- |
| `NEOCITIES_API_KEY` | API key used as a Bearer token |
| `NEOCITIES_SITENAME` | Default sitename/username for the login prompt |
| `NEOCITIES_PASSWORD` | Default password for the login prompt |

The config file is stored per platform:

| Platform | Location |
| --- | --- |
| Linux | `$XDG_CONFIG_HOME/neocities/config.json` (defaults to `~/.config/neocities/config.json`) |
| macOS | `~/Library/Application Support/neocities/config.json` |
| Windows | `%LOCALAPPDATA%\neocities\config.json` |
| FreeBSD / other | `~/.neocities/config.json` |

Remove the stored key with:

```bash
neocities-red logout -y
```

---

## CLI Commands

```text
push      Recursively upload a local directory to your site
upload    Upload individual files/folders to your site
delete    Delete files from your site
diff      Compare your local directory with your site
list      List files from your site
info      Show information and stats for your site
pull      Get the most recent version of files from your site
purge     Remove all files from your site (development only)
logout    Remove the stored API key from the config
version   Print the gem version
pizza     Order a free pizza
help      Show help for a command
```

### `push`

Recursively upload a local directory to your Neocities site. Respects
`.gitignore` rules by default.

| Flag | Description |
| --- | --- |
| `--no-gitignore` | Ignore `.gitignore` filtering and upload matching files |
| `--ignore-dotfiles` | Skip dotfiles/dot-directories |
| `-e`, `--exclude` | Exclude file/directory paths (repeatable) |
| `--dry-run` | Show intended actions without mutating remote |
| `--optimized` | Skip files whose SHA1 hash already matches the server |
| `--prune` | Delete remote files that do not exist locally |

```bash
neocities-red push .
neocities-red push . --optimized --ignore-dotfiles
neocities-red push . -e node_modules -e .git
neocities-red push . --dry-run
neocities-red push . --prune
```

### `diff`

Compare a local directory with the remote site and show added, modified, and
removed files.

| Flag | Description |
| --- | --- |
| `--ignore-dotfiles` | Skip dotfiles/dot-directories |
| `-e`, `--exclude` | Exclude file/directory paths (repeatable) |

```bash
neocities-red diff .
neocities-red diff ./my-website --ignore-dotfiles
neocities-red diff . -e secret.txt
```

### `upload`

Upload an individual file or folder to your site.

```bash
neocities-red upload index.html
neocities-red upload assets/ images/assets
```

### `list`

List files from your Neocities site.

| Flag | Description |
| --- | --- |
| `-d`, `--detail` | Show a detailed table with size, SHA1 hash, and last-updated timestamp |
| `-a`, `--all` | List the entire site (ignore the path argument) |

```bash
neocities-red list
neocities-red list images -d
neocities-red list -a
```

### `info`

Show information and statistics for a site (defaults to your own site).

```bash
neocities-red info
neocities-red info fauux
```

### `pull`

Download the most recent version of files from your site. Skips files that
haven't changed since your last pull.

| Flag | Description |
| --- | --- |
| `-q`, `--quiet` | Show a spinner instead of per-file output |

```bash
neocities-red pull
neocities-red pull --quiet
```

### `delete`

Delete one or more files from your site.

```bash
neocities-red delete old.html
neocities-red delete old.html archived/old.css
```

### `purge`

Delete **everything** from your site. Intended for development sites only —
use with care.

| Flag | Description |
| --- | --- |
| `-y`, `--yes` | Confirm the destructive action (required) |
| `--dry-run` | Show what would be deleted without deleting |

```bash
neocities-red purge -y
neocities-red purge -y --dry-run
```

### `logout`

Remove the stored API key from the config. Requires confirmation.

```bash
neocities-red logout -y
```

### `version` & `pizza`

```bash
neocities-red version   # print the gem version
neocities-red pizza     # order a free pizza (easter egg)
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

The client supports both API-key (`api_key:`) and basic-auth
(`sitename:`/`password:`) authentication, retries transient failures (429/5xx)
automatically, and exposes low-level helpers like `upload_hash`,
`delete_wrapper_with_dry_run`, `key`, and `download`.

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
- `NeocitiesRed::Services::Common` (`Exclusions`, `WorkerPool`, `Pizza`)

---

## Development

```bash
bundle install
bundle exec rspec     # run the test suite
bundle exec rubocop   # run the linter
bundle exec ruby bin/neocities-red   # run the CLI from source
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

---

## Contributing

see CONTRIBUTING.md

---

## License

MIT — see LICENSE

---

## Acknowledgements

Built for the Neocities community.
