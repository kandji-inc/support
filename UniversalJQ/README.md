# UniversalJQ

## ABOUT

- This project contains a distribution PKG, wrapped in a gzipped tarball, the contents of which include two child packages and runtime logic to install a platform-native binary of `jq` on either Intel (`x86_64`) or Apple silicon (`arm64`) Mac chipsets.
    - Both `arm64` and `x86_64` executables are sourced from precompiled binaries available on the [JQ's releases page](https://github.com/jqlang/jq/releases/).
- This `jq` binary installs in `/Library/KandjiSE` with the executable bit set for immediate invocation.
