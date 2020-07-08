// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ios_system",
    products: [
        .library(name: "ios_system", targets: ["awk", "curl_ios", "files", "ios_system", "shell", "ssh_cmd", "tar", "text"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/awk.xcframework.zip",
            checksum: "6d4ebca1296054c18c618554ccaed441caf76a8bf38865dad24cbec6ab8c0163"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "d7e8271c60c42cd6e7d175c851a0a3539eaffb3175b08f4abca9f3952ac3445c"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "d502927562ba4dbdd8e53bbe87fdb8ec0b3ec0819f2058d64fab48144e76d184"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "1b49abacc19e7f3eaee08202ba676fad0c4c16e9a3e4d7cb8a38ccf954c34d0b"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "1de0b1bd687710ccb825ad7b94258b13944a1fd99d8d3d8f6793131461fa6032"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "90633c3d4a34b6986bcd429dab314109bcb3fc02e0cbd3928df3b857869f147a"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "cdd45774b33f9655f2183519ffd9c319429c6c6f2d2e49fb0db267f555f41814"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "63141350d266ffa471cfe3ea5e55a450730e6a944f18c7c4de3e4f8a5c43b042"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/mandoc.xcframework.zip",
            checksum: "8dae6fb5790bf68bf347ab6cc402943a0c8a473d9166f9e5213e45c4c80078a8"
        )
    ]
)
