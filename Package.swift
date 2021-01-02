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
            checksum: "7da2c4c543717e4bf12a29fe1eab2353c58f315278302980b29a7b548e5721f8"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "cb39f9c77a8842649f45b4a0c3bc7f458491c09baeac597ff0332ec5f9c5a451"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "4d2a29efda7454c7dfd7a84154a0fa7497e43aff12cf0d17ec6eef895dbac9c7"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "0f2c47d261ed1f053ca624ef36a4b86be227532c0189d6f1b4f9c13b2da6ff9c"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "78e2c86758c55659e786fe17125c9231835dcfee1df16fd58032a0eb6f7dabb7"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "ff552dba5a3b0371e451adaed3855f4ce5c2e1fbb8370ab3774bbc8ab23db928"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "ff79f95625c9ba190a010f63fee032044f6b074fba1f5b5fce0ff94edec6d4de"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "df2e692adcb6f9a6e8ac80f108219f77af6f473a80a20f9ff6f76ea40726201b"
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

