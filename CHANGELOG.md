# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] — 2026-08-04

### Changed

- Major architecture refactor with namespaced services (`file/`, `site/`, `common/`)
- Renamed gem to `neocities-red`

### Added

- YARD documentation

### Removed

- Unused legacy code

## [1.1.2] — 2026-08-04

### Changed

- Bumped rubocop to 1.88.2, rubocop-rspec to 3.10.2, faraday to 2.14.3

## [1.1.1] — 2026-06-22

### Fixed

- Config for Windows/FreeBSD platforms
- Purge no longer removes already-removed files

### Changed

- `upload` accepts a single parameter
- Bumped rake to 13.4.2

## [1.1.0] — 2026-04-25

### Changed

- Added Rails/Thor CLI framework, refactored `cli.rb`

## [1.0.6] — 2026-04-14

### Fixed

- Tests and lint fixes
- Added `faraday-retry` for flaky API/SSL handling

## [1.0.4] — 2026-03-29

### Changed

- CLI version display updated

## [1.0.2] — 2026-02-11

### Added

- Multithreaded parallel uploads
- Fixed recursive uploading in `upload` method

## [1.0.1] — 2026-02-07

### Added

- Folder uploading support

## [1.0.0] — 2026-02-11

### Added

- Initial release of `neocities-red` (fork of `neocities-ruby`)
- Recursive uploads with smart diffing
- `push`, `upload`, `delete`, `diff`, `list`, `info`, `pull` commands
- Parallel upload workers
- Automatic retries
- Config file with `NEOCITIES_API_KEY` support

[Unreleased]: https://github.com/o-200/neocities-red/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/o-200/neocities-red/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/o-200/neocities-red/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/o-200/neocities-red/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/o-200/neocities-red/compare/v1.0.6...v1.1.0
[1.0.6]: https://github.com/o-200/neocities-red/compare/v1.0.4...v1.0.6
[1.0.4]: https://github.com/o-200/neocities-red/compare/v1.0.2...v1.0.4
[1.0.2]: https://github.com/o-200/neocities-red/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/o-200/neocities-red/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/o-200/neocities-red/releases/tag/v1.0.0
