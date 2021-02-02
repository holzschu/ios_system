// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ios_system",
    products: [
        .library(name: "ios_system", targets: ["ios_system", "awk", "curl_ios", "files", "shell", "ssh_cmd", "tar", "text", "mandoc"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ios_system.xcframework.zip",
            checksum: "e98c075c088f916649426720afa50df03904aa36d321fe072c9bd6ccbc12806c",
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/awk.xcframework.zip",
            checksum: "663554d7fca4fcdc670ab91c2f10c175bd10ca8dca3977fbeb6ee8dcd9571e05",
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/curl_ios.xcframework.zip",
            checksum: "bd1b1f430693c3dc3c0e03bccea810391e5d0d348fbd3ca2d31ff56b5026d1bb",
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/files.xcframework.zip",
            checksum: "c1fbd93d35d3659d3f600400f079bfd3b29f9f869be6d1c418e3ac0e7ad8e56a",
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/shell.xcframework.zip",
            checksum: "726bafd246106424b807631ac81cc99aed42f8d503127a03ea6d034c58c7e020",
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ssh_cmd.xcframework.zip",
            checksum: "8c769ad16bdab29617f59a5ae4514356be5296595ec5daf4300440a1dc7b3bf7",
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/tar.xcframework.zip",
            checksum: "25b817baab9229952c47babc2a885313070a0db1463d7cd43d740164bd1f951b",
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/text.xcframework.zip",
            checksum: "54acd52b21ae9cfa85e3c54d743009593dd78bf6b53387185fd81cf95d8ddf05",
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.7.0 

ios_system.xcframework.zip	e98c075c088f916649426720afa50df03904aa36d321fe072c9bd6ccbc12806c
awk.xcframework.zip	663554d7fca4fcdc670ab91c2f10c175bd10ca8dca3977fbeb6ee8dcd9571e05
curl_ios.xcframework.zip	bd1b1f430693c3dc3c0e03bccea810391e5d0d348fbd3ca2d31ff56b5026d1bb
files.xcframework.zip	c1fbd93d35d3659d3f600400f079bfd3b29f9f869be6d1c418e3ac0e7ad8e56a
shell.xcframework.zip	726bafd246106424b807631ac81cc99aed42f8d503127a03ea6d034c58c7e020
ssh_cmd.xcframework.zip	8c769ad16bdab29617f59a5ae4514356be5296595ec5daf4300440a1dc7b3bf7
tar.xcframework.zip	25b817baab9229952c47babc2a885313070a0db1463d7cd43d740164bd1f951b
text.xcframework.zip	54acd52b21ae9cfa85e3c54d743009593dd78bf6b53387185fd81cf95d8ddf05

*/
