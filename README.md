![Specs](https://github.com/taylorthurlow/crystal-build-cr/workflows/specs/badge.svg)

A rewrite of crystal-build in Crystal.

TODO: Write an actual README

## Installation

For a really basic installation, if a binary for your OS is included in the Releases page of this repository, rename the binary to `crenv-install`, and add that binary to `$CRENV_ROOT/plugins/crystal-build/bin/`. You won't have the ablility to uninstall Crystal versions with `crenv uninstall` this way.

To build from scratch, clone the repository and build it with an existing Crystal installation:

```bash
git clone https://github.com/taylorthurlow/crystal-build-cr.git $CRENV_ROOT/plugins/crystal-build
cd $CRENV_ROOT/plugins/crystal-build
crystal build --release src/build.cr -o bin/crenv-install
```

## Usage

```bash
crenv install 0.32.1
crenv uninstall 0.32.1
```

### Other Notes

Prepackaged Crystal distributions work fine, but because they aren't built from scratch on the local machine, you might run into library issues on macOS, like for SSL libraries. I solved the SSL library issue with:

```bash
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:"/usr/local/opt/openssl/lib/pkgconfig"
```
