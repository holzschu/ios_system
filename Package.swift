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
            checksum: "bd9cb1dbf46d22ceb3a836a9bf14de70aba60177308bdc0b6eca4d8fa2d91279"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "ebbc2d1904284482b03a788d4add954887f8830984eac9c46b838a1e08194a8c"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "50228e50b31f05ec347897c9cbc758bdc1a8b1a632fc3189e90d8e3ea0fa5875"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "a0e925e755e1c7a20d4bfc1a51f76cd6a6aad30e6146287b416ea22a4330315b"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "86c054231e81e3a9696432fa3c654d8bce3b5955844eae2bbd06d13df00fd033"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "64004658541d9a3f2baa3aacca257aa8d9eb9388e1963bac2a7605320952aa13"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "d8aff2597e7d4da8654fb470de9eb660968ecff20ef21d439bb244680184d2df"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "6f710c0dd7ed8ab0fe4fbf3aaaac1f040798eeea1ebc4898aa2c54e19b70d90e"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/mandoc.xcframework.zip",
            checksum: "9e4ce408f1ec66afae125782117a4a847dc17c83cbc8d105fa89a0415e86880b"
        )
    ]
)
/* 
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/awk.xcframework
d5cbe95490a244207c1aea0f7918d9f071d4a8c3a2e9d939fbc160af485c0ba0
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
d8780dcf1e64e1abe9bea3d5281c26ebada9c8769c6a75273736aabde5d370d3
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
a3f37618b50d403113d477775811ee4db0c3f27a306a68e9a9f04114698d7e1c
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
1ae111cd468e8764013a9d34944607b446cc43f181b51babf602646f4f620993
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
7a8a5ad7496089f45a0f9da39a1f1c44aa1aa1cf913ca57683df27e1798168c4
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
315a6448decd4d76c4d92701b15151444dc0261a1b0681b7d95a7d081a39d3fa
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
ee812634ab1dff10fa79d19782723c1b9624f6ce0146509a91cc3ebff247fb27
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
b6a733aa525cf191151197c97736a94a65fb0b690b3cba1d6ba65d8f4777bf79
*/

