// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ios_system",
    products: [
        .library(name: "ios_system", targets: ["ios_system", "awk", "curl_ios", "files", "shell", "ssh_cmd", "tar", "text", "mandoc"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ios_system.xcframework.zip",
            checksum: "6d52c62e84b47bbe1931faf118d2b20f8a5f6bb1dfa9cd630ad7d91c5e26b58f"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/awk.xcframework.zip",
            checksum: "d34ca66c2e3d0ec1c72eaab55762025266c911f67fffe206c195b4ae14bf0632"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/curl_ios.xcframework.zip",
            checksum: "f6e49bc32301af72a9b9535f1d34ddca8891e81364b38a73deeb77915bf40eee"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/files.xcframework.zip",
            checksum: "10c0513a18157af49c4697abc479a6dc3aa5d45f3a08749d1d1351e2ba8fbb39"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/shell.xcframework.zip",
            checksum: "6576fff46a9087a403df3febb96afb9590feb30397a1ddad7ed176648a2ce39e"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ssh_cmd.xcframework.zip",
            checksum: "300b07e77fdf37e7b5750ad6f1797a3ca465a4dee80c56c4a33643ba61fee57b"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/tar.xcframework.zip",
            checksum: "77e2b3ef9900270efa43490b77eb9da37e2d828ac694373fa8b7b57da10e5ed0"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/text.xcframework.zip",
            checksum: "a2d360825a6fc75ad352da8fb9df72a4dc6aa80dad071957e53556a1468d29e8"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.7.0 

ios_system.xcframework.zip	6d52c62e84b47bbe1931faf118d2b20f8a5f6bb1dfa9cd630ad7d91c5e26b58f
awk.xcframework.zip	d34ca66c2e3d0ec1c72eaab55762025266c911f67fffe206c195b4ae14bf0632
curl_ios.xcframework.zip	f6e49bc32301af72a9b9535f1d34ddca8891e81364b38a73deeb77915bf40eee
files.xcframework.zip	10c0513a18157af49c4697abc479a6dc3aa5d45f3a08749d1d1351e2ba8fbb39
shell.xcframework.zip	6576fff46a9087a403df3febb96afb9590feb30397a1ddad7ed176648a2ce39e
ssh_cmd.xcframework.zip	300b07e77fdf37e7b5750ad6f1797a3ca465a4dee80c56c4a33643ba61fee57b
tar.xcframework.zip	77e2b3ef9900270efa43490b77eb9da37e2d828ac694373fa8b7b57da10e5ed0
text.xcframework.zip	a2d360825a6fc75ad352da8fb9df72a4dc6aa80dad071957e53556a1468d29e8

*/
