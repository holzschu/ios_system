// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ios_system",
    products: [
        .library(name: "ios_system", targets: ["awk", "curl_ios", "files", "ios_system", "shell", "ssh_cmd", "tar", "text", "mandoc"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/awk.xcframework.zip",
            checksum: "871aa11ad9c2cd35beef98f713c997d00f0c43be3558f89c70bd5472923076e3"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "8518c91a67fae789f0ba3274412c4ce6f9b072fcf5da878bb5d48413a51eef1b"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "246ad62579d0bee98b0afda3b39b04c32387f2d885e22c5b6e5b1e6bd15d36b8"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "2e27e36a4770ef57a1ed1d1764e32e869b2ec64fcbd47c3d678fb4a62e09adbf"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "1d89e218e0455b6cb18a727112c9c9165fdf914ac5a94d2191e2288a3567b64b"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "b4bd0a8a6318f4efeef3c8fb6051ffa82343e3ca832cd94ea7507cf2657aca7d"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "c7caa611ab49fd78ba058c2c2b3515c320aa3273ce9b6b4dbb561b4d6d6899a9"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "3a15ce0cd715b9dc2219c547fb3efcfecc3c99dbe18d58ab828f7994cfc0da5b"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/mandoc.xcframework.zip",
            checksum: "aabef1654771a373bf317b9be092ace5d84a515f03ad291c63b793ac8997be57"
        )
    ]
)
/* 
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/awk.xcframework
871aa11ad9c2cd35beef98f713c997d00f0c43be3558f89c70bd5472923076e3
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
8518c91a67fae789f0ba3274412c4ce6f9b072fcf5da878bb5d48413a51eef1b
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
246ad62579d0bee98b0afda3b39b04c32387f2d885e22c5b6e5b1e6bd15d36b8
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
2e27e36a4770ef57a1ed1d1764e32e869b2ec64fcbd47c3d678fb4a62e09adbf
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
1d89e218e0455b6cb18a727112c9c9165fdf914ac5a94d2191e2288a3567b64b
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
b4bd0a8a6318f4efeef3c8fb6051ffa82343e3ca832cd94ea7507cf2657aca7d
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
c7caa611ab49fd78ba058c2c2b3515c320aa3273ce9b6b4dbb561b4d6d6899a9
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
3a15ce0cd715b9dc2219c547fb3efcfecc3c99dbe18d58ab828f7994cfc0da5b
*/
