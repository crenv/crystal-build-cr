![Specs](https://github.com/crenv/crystal-build-cr/workflows/specs/badge.svg)

## crystal-build

**Disclaimer**: This is an in-progress rewrite of `crystal-build` in Crystal. While largely functional, the existing application is written in Perl and in general it's hard to find maintainers, and people who are willing to work on Perl projects. 

`crystal-build` is a plugin for [`crenv`](https://github.com/crenv/crenv) which provides a `crenv install` command. This command facilitates downloading and building/installing specific versions of Crystal and Shards.

Currently this project only supports downloading and installing Crystal from a released Crystal binary from the [crystal-lang GitHub releases page](https://github.com/crystal-lang/crystal/releases). Building Crystal from source is a feature that is on the roadmap. Shards, if not included in the GitHub release, will be built and installed from source.

### Installation

For a really basic installation, if a binary for your OS is included in the Releases page of this repository, rename the binary to `crenv-install`, and add that binary to `$CRENV_ROOT/plugins/crystal-build/bin/`. You won't have the ablility to uninstall Crystal versions with `crenv uninstall` this way.

To build from scratch, clone the repository and build it with an existing Crystal installation. If you don't have an existing Crystal installation and you use macOS, the easiest way is to install `crystal` using homebrew. 

```bash
git clone https://github.com/taylorthurlow/crystal-build-cr.git $CRENV_ROOT/plugins/crystal-build
cd $CRENV_ROOT/plugins/crystal-build
shards install
crystal build --release src/build.cr -o bin/crenv-install
```

### Usage

```
crenv install [options] <version>
    -h, --help                       Print this help
    -v, --verbose                    Enable verbose output
    --version                        Print the version number
    -l, --list                       Print a list of available Crystal versions
```

Install a specific version of Crystal with:

```bash
crenv install 0.32.1
```

If you compile from source you should also have access to `crenv uninstall <version>`. If you just copied the binary and you don't have the uninstall command, you can achieve the same effect by removing the desired directory from `$CRENV_ROOT/versions`. You can add a simple uninstall script with this command:

```bash
echo "rm -r $CRENV_ROOT/versions/$1" > $CRENV_ROOT/plugins/crystal-build/bin/crenv-uninstall
```

