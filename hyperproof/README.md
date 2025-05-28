# Hyperproof

This is a system to collect evidence (proofs) of our security and compliance
posture, and sync them with our compliance management system ([Hyperproof]).

## Usage

You can run the system from GitHub Actions (recommended), or locally.

### GitHub Actions

Run the [Hyperproof Sync][workflow] from the GitHub Actions tab of this
repository. Alternatively, if you have the [GitHub CLI][gh] installed, you can
run the workflow from the command line:

```bash
gh workflow run hyperproof.yaml
```

### Locally

If you want to run the system locally — to test changes or debug issues, for
example — you will first need to install the necessary dependencies. Use your
favorite ruby version manager to install the required [version of
ruby][ruby-version].

Make sure you've switched to the `hyperproof` directory in the repository, then
install the dependencies using `bundler`:

```bash
cd hyperproof
bundle install
```

You should now be able to run use the provided CLI command. You can check the
current version to verify that everything is working:

```bash
./bin/hyperproof version
```

If you see the version number, you're good to go! You can now run the full
system with:

```bash
./bin/hyperproof collect
```

[gh]: https://cli.github.com/
[hyperproof]: https://hyperproof.io/
[ruby-version]: https://github.com/codeforamerica/cfa-security-controls/tree/main/hyperproof/.ruby-version
[workflow]: https://github.com/codeforamerica/cfa-security-controls/actions/workflows/hyperproof.yaml
