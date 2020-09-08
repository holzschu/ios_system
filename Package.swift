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
            checksum: "76cbc32aa920ef513e663a5b89d45a06cf7cded3636b504260be2c6d30ce73a9"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "f45fabee8e94fe502c06ff5cb4d325776e2716d145d65bf23fcd5e610864220d"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "451bb733d70981c3a47c4912614020ee489376dd8f287f324fcc71197277530a"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "b47568be5a9a239eb55ac20b9b883a31ced042857d00dc4d974e6b3ba15b066e"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "58eb5e3389171e416696556662504f54d3c68b0c0fdb658758e638bead8e82d2"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "461f0b15c0c7fa42becadaa5423c9ce3362fdb9572d8445fc7953b7f19830fe2"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "1c34e4fbfa3a7a2f19db559e2a62f665e130d6964caeb5e715794c4478d50f38"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "2e7f0a1a59953644df7634149c3106e6b57dd31fd8c5ba3a5e7e9bbd31dfee45"
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
76cbc32aa920ef513e663a5b89d45a06cf7cded3636b504260be2c6d30ce73a9
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
f45fabee8e94fe502c06ff5cb4d325776e2716d145d65bf23fcd5e610864220d
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
451bb733d70981c3a47c4912614020ee489376dd8f287f324fcc71197277530a
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
b47568be5a9a239eb55ac20b9b883a31ced042857d00dc4d974e6b3ba15b066e
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
58eb5e3389171e416696556662504f54d3c68b0c0fdb658758e638bead8e82d2
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
461f0b15c0c7fa42becadaa5423c9ce3362fdb9572d8445fc7953b7f19830fe2
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
1c34e4fbfa3a7a2f19db559e2a62f665e130d6964caeb5e715794c4478d50f38
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
2e7f0a1a59953644df7634149c3106e6b57dd31fd8c5ba3a5e7e9bbd31dfee45
*/

