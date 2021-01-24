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
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/awk.xcframework.zip",
            checksum: "2229725d1fce3af96171718ae9f33791841fe573a7b8a473d8f5aba7885c7db6"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/curl_ios.xcframework.zip",
            checksum: "1407c6d2cd1721e398bcbf052c5b4034bac891a3a8d09d2489ab5a774bccd806"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/files.xcframework.zip",
            checksum: "1f735f99a1f4cde3492431b345b2815561faa84228b08e1352a68e13242a0c25"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/ios_system.xcframework.zip",
            checksum: "7eba200145a66b5dc1bfcef5452886176f9e5baaa90bd3186c79528f69121979"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/shell.xcframework.zip",
            checksum: "cd6113754616f83043dcb3c950a89df73fa8aad7aa0ccc2c59e758dd5c4c6ef3"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/ssh_cmd.xcframework.zip",
            checksum: "1edef1e1ee49ee8585eb732ab9904243f5a5e1effdd7d147540d6a53fc9ea93e"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/tar.xcframework.zip",
            checksum: "e99ca965f981ecd3e149791419e552f03ac4711a9e45dbec56d23a06f983f87c"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/text.xcframework.zip",
            checksum: "b3182206ebceadf71a8e288112afd4d852b5360426bb469e79b3bac0e143fd44"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* 
    | File                            | SHA 256                                             |
    | ------------------------------- |:---------------------------------------------------:|
    | ios_system.xcframework.zip | 7eba200145a66b5dc1bfcef5452886176f9e5baaa90bd3186c79528f69121979 |
    | awk.xcframework.zip | 2229725d1fce3af96171718ae9f33791841fe573a7b8a473d8f5aba7885c7db6 |
    | tar.xcframework.zip | b6374d9a76e84d8192e5e7838fea76b98af84f8a62dfa8f9e86beede3a13954b |
    | curl_ios.xcframework.zip | 1407c6d2cd1721e398bcbf052c5b4034bac891a3a8d09d2489ab5a774bccd806 |
    | files.xcframework.zip | 1f735f99a1f4cde3492431b345b2815561faa84228b08e1352a68e13242a0c25 |
    | shell.xcframework.zip | cd6113754616f83043dcb3c950a89df73fa8aad7aa0ccc2c59e758dd5c4c6ef3 |
    | ssh_cmd.xcframework.zip | 1edef1e1ee49ee8585eb732ab9904243f5a5e1effdd7d147540d6a53fc9ea93e |
    | tar.xcframework.zip | e99ca965f981ecd3e149791419e552f03ac4711a9e45dbec56d23a06f983f87c |
    | text.xcframework.zip | b3182206ebceadf71a8e288112afd4d852b5360426bb469e79b3bac0e143fd44 |
*/

