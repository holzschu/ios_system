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
            checksum: "5c87bee34330a22686b0297933b57c8dcb3eeb9f9b066a198e9cfd386af0c4f1"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "630b3e08e22e727e76e6dc91e5b9c2c855503fabcf0675d0d3111c11322b849d"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "6c5c7483bd1eea53acf45c7c6e4a5a10c95f67aa36b9c655cdb9e99d2854ed87"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "d3eb5ca5ea726b3470b4bafe25157c14a0ba85c57aa9ee579627a27f30b973cf"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "8eec05b685bd130461036941af18d217b9476790f7609637216151a31f37ce1b"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "9f297e946ee4d4d10971986bdcaf3ec76dd3bc7f8c5e448ff0444f378e3dc9c2"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "bf8c1e00baa5ea675e78c016272a780b0fe29eb8f38a3278ae53a4a417828a0e"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "a7a10071db6c53bc6a7096e1159a4a5e24f599d10d4743b08db2b6751e4278af"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/mandoc.xcframework.zip",
            checksum: "02f4dc12ddfb1286e855056cb9fa51dc1dad34e60498406f8570d63a96f23552"
        )
    ]
)
/* 
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/awk.xcframework
5c87bee34330a22686b0297933b57c8dcb3eeb9f9b066a198e9cfd386af0c4f1
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
630b3e08e22e727e76e6dc91e5b9c2c855503fabcf0675d0d3111c11322b849d
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
6c5c7483bd1eea53acf45c7c6e4a5a10c95f67aa36b9c655cdb9e99d2854ed87
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
31d6e18d518905883894b8cdc8329ca217d2c40697a4912c45a01a2464bf1521
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
8eec05b685bd130461036941af18d217b9476790f7609637216151a31f37ce1b
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
9f297e946ee4d4d10971986bdcaf3ec76dd3bc7f8c5e448ff0444f378e3dc9c2
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
bf8c1e00baa5ea675e78c016272a780b0fe29eb8f38a3278ae53a4a417828a0e
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
a7a10071db6c53bc6a7096e1159a4a5e24f599d10d4743b08db2b6751e4278af
*/
