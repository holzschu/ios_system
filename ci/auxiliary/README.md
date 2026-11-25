# Auxiliary command frameworks

Run `bash build-auxiliary.sh` from the repository with Xcode and uv installed. The outputs are in `.build/auxiliary`: SHA-256 checksums and three XCFramework ZIPs for arm64 iOS and arm64/x86_64 Simulator at deployment target 14.

The recipe builds BSD make 20200606, mandoc 1.14.5 and UnRAR 6.02 against ios_system 3.0.5. The make and mandoc adaptations were reconstructed from the published binaries. Make's job mode runs serially. The build compares exported names and checks import changes against the published Auxiliary binaries.

The workflow uploads the same ZIPs and audit reports for review.
