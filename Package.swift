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
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/ios_system.xcframework.zip",
            checksum: "4f8ff7fba7a053d8cbd79abb505c2c71c0c9756d5eea64e845dee6f0946ea032"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/awk.xcframework.zip",
            checksum: "cea938659311902471d64e5345294780d364f20f983ae701ddd52870afb0bceb"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/curl_ios.xcframework.zip",
            checksum: "d21c43012a1966109f05a1f0c45bbcd74102204d9025ee243f4c0b31ae3651a7"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/files.xcframework.zip",
            checksum: "2c6a028702519e823481310676407c6525f652db7e9bfdb84680bfc89263e0c8"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/shell.xcframework.zip",
            checksum: "9af7f9d87e1bc1e26ff7c076959ee08a2d6b6584b56bbf772bcdbe43563bdb10"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/ssh_cmd.xcframework.zip",
            checksum: "a3f19cd39b4ecb8e4f0983c4cbd78febc52a05e547ea4bdc85ddf74c2789b3ee"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/tar.xcframework.zip",
            checksum: "13a188649adcb25ca483dcc35b4fd91538ba9629dd15e845cf7bac28f84d7526"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.8.0/text.xcframework.zip",
            checksum: "c56d164d7c0fd37d88f265fbd2aca47cd21dc42db536af33a1a469660794ad98"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.8.0 

ios_system.xcframework.zip	4f8ff7fba7a053d8cbd79abb505c2c71c0c9756d5eea64e845dee6f0946ea032
awk.xcframework.zip	cea938659311902471d64e5345294780d364f20f983ae701ddd52870afb0bceb
curl_ios.xcframework.zip	d21c43012a1966109f05a1f0c45bbcd74102204d9025ee243f4c0b31ae3651a7
files.xcframework.zip	2c6a028702519e823481310676407c6525f652db7e9bfdb84680bfc89263e0c8
shell.xcframework.zip	9af7f9d87e1bc1e26ff7c076959ee08a2d6b6584b56bbf772bcdbe43563bdb10
ssh_cmd.xcframework.zip	a3f19cd39b4ecb8e4f0983c4cbd78febc52a05e547ea4bdc85ddf74c2789b3ee
tar.xcframework.zip	13a188649adcb25ca483dcc35b4fd91538ba9629dd15e845cf7bac28f84d7526
text.xcframework.zip	c56d164d7c0fd37d88f265fbd2aca47cd21dc42db536af33a1a469660794ad98*/
