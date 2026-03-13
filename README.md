# asdf-simc

[simc](https://github.com/BlockstreamResearch/SimplicityHL) plugin for [asdf](https://asdf-vm.com/).

Manages versioned installs of the Simplicity compiler from [SimplicityHL](https://github.com/BlockstreamResearch/SimplicityHL).

## Prerequisites

- [asdf](https://asdf-vm.com/guide/getting-started.html)
- Rust toolchain (rustc >= 1.79.0) — install via [rustup](https://rustup.rs/)

`cargo` must be available on your `$PATH` before installing any version of `simc`.

## Install plugin

```bash
asdf plugin add simc https://github.com/stringhandler/asdf-simc
```

## Usage

```bash
# List all available versions
asdf list all simc

# Install a version (builds from source, takes ~1-2 minutes)
asdf install simc 0.4.1

# Set version globally
asdf global simc 0.4.1

# Set version per project (writes .tool-versions)
asdf local simc 0.4.1

# Verify
simc --version
```

## How it works

SimplicityHL does not publish prebuilt binaries. This plugin:

1. Fetches available versions from git tags in the SimplicityHL repo
2. Downloads the source tarball for the requested version
3. Runs `cargo build --release` to compile `simc`
4. Places the binary in asdf's versioned install path

## License

MIT
