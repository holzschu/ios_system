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
            checksum: "7bb4fae5480f7eef48c485234ce5ee9888e0ff5bed3b2ac446416a7b799c0de3"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "a027f5ffdfd8d6e5067f52929522268db28b59d54d5f15ff26c8c84beef98c78"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "7e34756dda019229963e0e36e6b8368b9826eacfc96ee21ff5800ccca79e6577"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "872e53659ac71088b40a9dcc3bc2ae745015f228c4167d882cef06686dd493ae"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "60d30bd77442042ffd1e807e38d2c2b564d3fb25c45b0fc20189f4ea134284d7"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "084c01f5c86065a4be89dc281178e9f12eb8af71eb6d63ca9664f58eeddcb33c"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "2d0ccdc07d867adf80be8d4e32a6fcebe3d3ac5b825d1d9e15eab9bd2d537776"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "91f7e831f7b1924bbc29fdfb5f3b629e5f91cbe2063b677e53ee8b50de415eb5"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* 
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/awk.xcframework
7bb4fae5480f7eef48c485234ce5ee9888e0ff5bed3b2ac446416a7b799c0de3
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
a027f5ffdfd8d6e5067f52929522268db28b59d54d5f15ff26c8c84beef98c78
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
7e34756dda019229963e0e36e6b8368b9826eacfc96ee21ff5800ccca79e6577
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
872e53659ac71088b40a9dcc3bc2ae745015f228c4167d882cef06686dd493ae
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
60d30bd77442042ffd1e807e38d2c2b564d3fb25c45b0fc20189f4ea134284d7
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
084c01f5c86065a4be89dc281178e9f12eb8af71eb6d63ca9664f58eeddcb33c
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
2d0ccdc07d867adf80be8d4e32a6fcebe3d3ac5b825d1d9e15eab9bd2d537776
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
91f7e831f7b1924bbc29fdfb5f3b629e5f91cbe2063b677e53ee8b50de415eb5
*/

