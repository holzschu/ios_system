# jq xcframework

Run `bash build-jq.sh` from the repository root with Xcode and its iOS SDKs installed. Use a checkout path without spaces. The script downloads checksum-pinned official jq 1.8.2 and ios_system v3.0.5, builds jq with bundled Oniguruma 6.9.10, and writes `.build/jq/output/jq.xcframework.zip`, `checksums.txt` and `release.md`. No compiler or Autotools installation is needed. Build parallelism defaults to four jobs; set `JOBS` to change it.

The framework exports `main` for a-Shell's existing command registration, with arm64 iOS and universal arm64/x86_64 Simulator slices at iOS 14.0. The stream adapter routes standard input, output, errors, environment lookup and exit through ios_system. The source patch flushes stdout before returning because ios_system owns the stream. The host app supplies `ios_system.framework`.

The jq workflow builds on relevant pull requests and manual runs. A `jq-v1.8.2` tag in holzschu/ios_system publishes the ZIP, checksums and release notes. The release job has the only write token, runs only upstream, leaves the repository's latest release unchanged and refuses to overwrite existing assets. Update a-Shell's `jq` binaryTarget URL and checksum after publication.

The CI build verifies the exported entry point and linked dependencies; it does not run an iPhone app.
