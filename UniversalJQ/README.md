# UniversalJQ

## ABOUT

- This project contains a distribution PKG, wrapped in a gzipped tarball, the contents of which include two child packages and runtime logic to install a platform-native binary of `jq` on either Intel (`x86_64`) or Apple silicon (`arm64`) Mac chipsets.
    - The `x86_64` executable is sourced from the precompiled binary available on [JQ's releases page](https://github.com/stedolan/jq/releases/).
    - The `arm64` executable is also derived from the above location, but compiled from source using a modified build script originally created by [@magnetikonline](https://gist.github.com/magnetikonline/58eb344e724d878345adc8622f72be13)
- This `jq` binary installs in `/Library/KandjiSE` with the executable bit set for immediate invocation.
