# asdf-simc

[simc](https://github.com/BlockstreamResearch/SimplicityHL) plugin for [asdf](https://asdf-vm.com/).

Manages versioned installs of the Simplicity compiler from [SimplicityHL](https://github.com/BlockstreamResearch/SimplicityHL).

## Prerequisites

- [asdf](https://asdf-vm.com/guide/getting-started.html)

The plugin will automatically use prebuilt binaries when available for your platform. If no prebuilt binary exists (or you opt into source builds), you will also need:

- Rust toolchain (rustc >= 1.79.0) — install via [rustup](https://rustup.rs/)

## Install plugin

```bash
asdf plugin add simc https://github.com/stringhandler/asdf-simc
```

## Usage

```bash
# List all available versions
asdf list all simc

# Install a version (uses prebuilt binary if available)
asdf install simc 0.4.1

# Set version globally
asdf global simc 0.4.1

# Set version per project (writes .tool-versions)
asdf local simc 0.4.1

# Verify
simc --version
```

## Prebuilt binaries vs. build from source

By default, the plugin downloads a prebuilt binary from the SimplicityHL GitHub releases when one is available for your platform.

| Platform | Architectures |
|---|---|
| Linux | x86\_64, aarch64 |
| macOS | x86\_64, aarch64 (Apple Silicon) |
| Windows | x86\_64 |

If your platform is not listed above, the plugin automatically falls back to building from source (requires `cargo`).

To force a source build on any platform, set the environment variable before installing:

```bash
ASDF_SIMC_BUILD_FROM_SOURCE=1 asdf install simc 0.4.1
```

## How it works

1. Fetches available versions from git tags in the SimplicityHL repo
2. If a prebuilt binary is available for your platform, downloads it directly
3. Otherwise, downloads the source tarball and runs `cargo build --release`
4. Places the binary in asdf's versioned install path

## License

MIT
