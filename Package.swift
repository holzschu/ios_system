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
            checksum: "8c4bdf31ed8fb997706b7d5bef9dd86549069d86a0ee9ca13d6da1009377057c"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "e4db23176d19f646f75090dc4dc41749d32af68c492b3dee2c24eb773efb8632"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "5966d6c0e7bbf847780e0cfe1b55009719b5bb3e9671accf4682e1596cbbf024"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "092ad07cd83aafa810ca5fb6a6ed615f2be78f2120486a1cd5c962864a6e5746"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "173a6af34cc300a3ca6ef313acfb4bc104ac3270a33ebd0d4fd8d7358f83e9ca"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "eeab1e2715ef53a3e47d297e3ed580175133000c8f887e9a36254416253266a4"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "37b18e43adb7531d9bc0e413b0bd4a37df31da9b415746aa40a10b8d75820fe4"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "afac71a875d0889d7ebea47ffe1caa105e2473415ca3e2da8c2b37b25534eeee"
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
8c4bdf31ed8fb997706b7d5bef9dd86549069d86a0ee9ca13d6da1009377057c
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
e4db23176d19f646f75090dc4dc41749d32af68c492b3dee2c24eb773efb8632
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
5966d6c0e7bbf847780e0cfe1b55009719b5bb3e9671accf4682e1596cbbf024
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
092ad07cd83aafa810ca5fb6a6ed615f2be78f2120486a1cd5c962864a6e5746
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
173a6af34cc300a3ca6ef313acfb4bc104ac3270a33ebd0d4fd8d7358f83e9ca
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
eeab1e2715ef53a3e47d297e3ed580175133000c8f887e9a36254416253266a4
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
37b18e43adb7531d9bc0e413b0bd4a37df31da9b415746aa40a10b8d75820fe4
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
afac71a875d0889d7ebea47ffe1caa105e2473415ca3e2da8c2b37b25534eeee

