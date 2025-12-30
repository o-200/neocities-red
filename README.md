# Neocities Red

Hello, there is a fork of [neocities-ruby gem](https://github.com/neocities/neocities-ruby) with my own features and implementations. A much of my changes doesn't make sense to be pushed into original repository, so i pushed it here.

## Main changes/Features:

1) Added MultiThread uploading of files to neocities. This feature boosts `neocities push`.
2) Moves from `http.rb` to `faraday` gem.
3) Added excluding folders (recursively with their files). Probably [bug](https://github.com/neocities/neocities-ruby/pull/67).

## TODO'S:
2) Check all entire cli and client logic, fix bugs.
3) Change dependencies for modern analogs.
4) Refactor `cli.rb` or use `rails/thor` gem instead.
5) Do not push files to neocities which already exists, check their hash-sums before uploading.
6) Ignore dotfiles (?) while uploading and pulling files
7) Add tests
8) Make sure that gem is compatible with Linux, Freebsd, Windows

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
