[<img src="https://yesterhost.neocities.org/archive/buttons/button258.png" />](https://neocities.org)
[<img src="https://img.shields.io/badge/Ruby-CC342D?style=flat&logo=ruby&logoColor=white" />]()
[![Gem Version](https://badge.fury.io/rb/neocities-red.svg)](https://badge.fury.io/rb/neocities-red)
[![Made With Love](https://img.shields.io/badge/Made%20With-Love-orange.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Neocities Red

Hello, there is a fork of [neocities-ruby gem](https://github.com/neocities/neocities-ruby) with my own features and implementations. A much of my changes doesn't make sense to be pushed into original repository, so i pushed it here.

# The Neocities Gem

A CLI and library for using the Neocities API. Makes it easy to quickly upload, push, delete, and list your Neocities site.

## List of improvements/changes:

### 0) Refactor all entire project, change dependencies for more flexibility.

Currently, implementing new features in `neocities-red` is easier than at original cli. Also i approaching the philosophy to use modern dependencies to ensure that `neocities-red` will supports newest versions of Ruby.

### 1) upload

- Uploading is multi-threaded (Instead of uploading by 1 file linnear it uploads 3-5 files at once.)
- The logic is differs of original gem. 
- Command also uploads folders recursively (It also upload the content that is inside of the target directory).

### 2) push

Now, that command is great for users, which uses static site generators (like Jekyll, Hugo, e.t.c.).

- Uploading is multi-threaded (Instead of uploading by 1 file linnear it uploads 3-5 files at once.)
- `neocities push --optimized .` command is uploads only files which differs or missing.
- `neocities push --ignore-dotfiles .` is ignores all files/directories with '.' at the beginning.
- `neocities push -e <folder> .` is ignores folders recursively (Ignoring the content that is inside of the target directory).

## TODO'S:

1) Refactor `cli.rb` or use `rails/thor` gem instead.
2) Add tests.
3) Make sure that gem is compatible with Linux, Freebsd and Windows

## Installation

#### Currently, neocities-red tests and develop with ruby 3.4.* and supports 4.*


1) Install Ruby Programming Language to your system. 
- If you're not a programmer - just install version directly from https://www.ruby-lang.org/en/.
- If you're programmer - just use any of tools to install Ruby. I am prefer to use `asdf` of `mise`.

2) Install gem just typing:

```bash
gem install neocities-red
```

### Running

After that, you are all set! Run `neocities-red` in a command line to see the options and get started.

## Gem modules

This gem also transpose all processes to several class in lib/neocities, which could be used to write code that interfaces with the Neocities API.

```ruby
require 'neocities-red'

# use api key
params = {
  api_key: 'MyKeyFromNeocities'
}

# or sitename and password
# params = {
#  sitename: 'petrapixel,
#  password: 'mypass'
# }

client = Neocities::Client.new(params)
client.key
client.upload(path, remote_path)
client.info(sitename)
client.delete(path)
client.push(path)
client.list(path)
```

Also, you can use specific service for your needs:

```ruby
client = Neocities::Client.new(sitename: 'o200' , password: 'my-super-duper-password') 
detail = true
path = '.'

Neocities::Services::FileList.new(client, path, detail).show

# [
#   {
#     path: "assets", 
#     is_directory: true, 
#     created_at: "Sat, 07 Feb 2026 12:26:51 -0000", 
#     updated_at: "Sat, 07 Feb 2026 12:26:51 -0000"
#   },
#   ...
# ]

```

# Contributions ..?

I'm glad to see everyone, so for contribution you need to check issues and take one typing something like "i'd like to take this issue". After that you should to make fork of this repository, create new branch, complete the task and share with solution via pull request. 

If there are no tasks, just ping me (o-200) for the new issue, and we will think together about what can be implemented or fixed.

Also, before contribution, please read [CONTRIBUTING.md](CONTRIBUTING.md)
