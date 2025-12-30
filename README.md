# Neocities Red

Hello, there is a fork of [neocities-ruby gem](https://github.com/neocities/neocities-ruby) with my own features and implementations. A much of my changes doesn't make sense to be pushed into original repository, so i pushed it here.

## Main changes/Features:

### Currently, this gems tests with ruby 3.4.*

1) Added MultiThread uploading of files to neocities. This feature boosts `neocities push`.
2) Moves from `http.rb` to `faraday` gem.
3) Fixed -e flag to exclude folders recursively
4) Added `--ignore-dotfiles` to ignore all files-folders starts with '.'
5) Added `--optimized` flag to upload only modified files
6) Fixed bug with `neocities info` on modern rubies

## TODO'S:
1) Check all entire cli and client logic, fix bugs.
2) Change dependencies for modern analogs.
3) Refactor `cli.rb` or use `rails/thor` gem instead.
4) Add tests
5) Make sure that gem is compatible with Linux, Freebsd, Windows
6) Make it compatible with ruby 4.0.0

# The Neocities Gem

A CLI and library for using the Neocities API. Makes it easy to quickly upload, push, delete, and list your Neocities site.

## Installation

1. Download this repository:
```bash
git clone https://github.com/o-200/neocities-ruby.git
```

2. Build gem:
```bash
gem build neocities.gemspec
```

3. Install gem: 
```bash
gem install neocities-1337.gem
```
### Running

After that, you are all set! Run `neocities` in a command line to see the options and get started.

## Neocities::Client

This gem also ships with Neocities::Client, which you can use to write code that interfaces with the Neocities API.
