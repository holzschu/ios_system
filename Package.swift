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
            checksum: "19a626d8f287b184326ba488e1ae6bdc751a94e42fc6bf4befde1f1ff27c81af"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "7bfe8663dd09845a53ee658c1a9aa89b5337fac3c704d7c3b959d651f339d063"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "2e2854239675f2dc17453834777fe01614b31d7c3b32da65764fec99c672a1e9"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "f57e41414b144dcdfb63a2d109db2ec048438f328f1d308321dafb3de1002327"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "71118a0d66c7e83f44eba76ef4e36f210349a22e1a0b2277df17856fe7e6f4d9"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "e62533e953d9615ca8bc76ba0292aae8dd0fd92ecb10c3ba87ed089e8604d1c0"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "0ceefad5b792d7b6d490cd41a09322323a332fd7f379dc141938c70d0000a332"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "161a7f03ab3d54e9ee64d7f7473971979769a4c4f4806b32dab9c235e0d3f7be"
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
19a626d8f287b184326ba488e1ae6bdc751a94e42fc6bf4befde1f1ff27c81af
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
7bfe8663dd09845a53ee658c1a9aa89b5337fac3c704d7c3b959d651f339d063
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
2e2854239675f2dc17453834777fe01614b31d7c3b32da65764fec99c672a1e9
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
f57e41414b144dcdfb63a2d109db2ec048438f328f1d308321dafb3de1002327
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
71118a0d66c7e83f44eba76ef4e36f210349a22e1a0b2277df17856fe7e6f4d9
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
e62533e953d9615ca8bc76ba0292aae8dd0fd92ecb10c3ba87ed089e8604d1c0
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
0ceefad5b792d7b6d490cd41a09322323a332fd7f379dc141938c70d0000a332
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
161a7f03ab3d54e9ee64d7f7473971979769a4c4f4806b32dab9c235e0d3f7be
*/
