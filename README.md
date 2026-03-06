# Code for America Security Controls

This repository contains the configuration and automation for our security
controls. These ensure that our organization is secure and meets our compliance
requirements.

## Components

The following components are included in this repository:

- [Hyperproof Sync][hyperproof]
- AWS Macie configuration
- AWS Security Hub automations

[hyperproof]: docs/components/hyperproof.md

## Development setup

### Pre-commit hooks

This repository uses [pre-commit](https://pre-commit.com) to enforce code
style checks before each commit. Install it once after cloning:

**1. Install pre-commit**

```sh
brew install pre-commit
```

**2. Install the git hook**

```sh
pre-commit install
```

This symlinks the hook into `.git/hooks/pre-commit`. The checks will now run
automatically on every `git commit`. To run them manually against all files:

```sh
pre-commit run --all-files
```