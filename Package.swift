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
            checksum: "a988ef4fb8507dc5d7c02a518de43f2d8dd092b959b913eeeaf58577d17fbac6"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "b4c8a3d98c89bf586a64cbfd4255df593fb6310ac226c5ea64b7ce2666b5e684"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "a10f04c094aef05617b9aa8faebe58c3e632b544600240f07539075c57d1d9c9"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "8faec6b4b4e13f3b9942a33c7966cdc55d6add8f1b39b6e9b647e31af8087c20"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "e4330f181aba1e01e6bf2c7c195347c892e55c5afda08739c4c9be404d77c30b"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "a7531795e020fc4f296e263bb1e192121da2ee0cb124cf44789bf34222577f96"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "df4b5c7e9650ae884bc889fd2890a5c5276cb372e29c47e2c551515c8f46d431"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "45852fff09627720d171e12b5c23869e32c617f35da9292c40bef3c02f9efaed"
        )
    ]
)
