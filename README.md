<!-- markdownlint-disable MD033 MD036 -->
<h1>shinc</h1>

Generate bash CLI scripts using the [argc][argc] command. Provides a set of tools for managing shell script projects.

---

**Table of Contents**

- [Features](#features)
- [Installation](#installation)
  - [From Homebrew](#from-homebrew)
  - [Building from Source](#building-from-source)
    - [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Development](#development)
  - [Release](#release)
  - [Project Structure](#project-structure)
- [License](#license)

## Features

- Shell script formatting with [shfmt][shfmt]
- Man page generation
- Shell completions (bash, zsh, fish)
- Binary distribution
- Release management with version control

## Installation

### From Homebrew

You can install `shinc` using Homebrew:

```sh
brew install druagoon/brew/shinc
```

### Building from Source

#### Prerequisites

Required tools:

- `gawk`/`awk` - Text processing
- `gsed`/`sed` - Stream editor
- `shfmt` - Shell script formatter
- `yq` - YAML/JSON processor
- `argc` - CLI argument parser
- `git` - Control system used for tracking changes
- `git-cliff` - Changelog generator (for releases)

```sh
# Clone the repository
git clone https://github.com/druagoon/shinc
cd shinc

# Build the project
make build
```

## Configuration

Create `.config/shinc/config.toml` in your project:

```toml
[project]
name = "your-project"       # Project name
version = "0.1.0"           # Version
include = [                 # Files to include in distribution
  "bin",
  "contrib",
  "share",
  "LICENSE",
  "README.md"
]
```

## Development

### Release

To create a new release:

First you should build the project

```sh
make build
```

And run the release command with the new version:

```sh
./bin/shinc release <version>
```

This will:

- Update version in `.config/shinc/config.toml` and `src/main.sh`
- Update `CHANGELOG.md` using `cliff.toml` configuration by `git-cliff`
- Create a git commit and tag
- Push commit and tag to the remote repository

Then the release workflow will automatically:

- Build the binaries
- Create a GitHub release
- Update the Homebrew formula

### Project Structure

- `src` - Source code
- `share` - Share files
- `contrib` - Generated man pages and completions
- `bin` - Compiled binaries
- `build` - Build artifacts
- `dist` - Distribution files

## License

MIT License - see `LICENSE` file for details.

[argc]: https://github.com/sigoden/argc
[shfmt]: https://github.com/mvdan/sh
