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
            checksum: "7680ddfbc9ee41eecec13a86cb5a5189b95c8ec9dab861695c692b85435bbdf2"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/awk.xcframework.zip",
            checksum: "dad5fe7a16a3f32343c53cb22d9a28a092e9ca6e8beb0faea4aae2c15359e8db"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/curl_ios.xcframework.zip",
            checksum: "168bf3b37d8c14d0915049ea97a3d46518d855df488da986b876fc09df50af9f"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/files.xcframework.zip",
            checksum: "7494be7319ef73271e2210e8ecf2ea2b134a35edb5ed921b9ca64c3586d158f3"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/shell.xcframework.zip",
            checksum: "898d61af490747ccc1f581504c071db7508c816297985f9022cc6f2f21d19673"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ssh_cmd.xcframework.zip",
            checksum: "78d1b7c14c9447465cb49f1defd195e62dd77a4e4e2bc6762d8363754e2eee40"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/tar.xcframework.zip",
            checksum: "1b8eb72a7e38714aa265441dc28ff1963b13990f67c660b9b058fffad11a4264"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/text.xcframework.zip",
            checksum: "fcde883ff2d8f7d1cc43e9d4a80f01df8ab8d6e42515c4492f2fcc7a05b79afa"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.7.0 

ios_system.xcframework.zip	7680ddfbc9ee41eecec13a86cb5a5189b95c8ec9dab861695c692b85435bbdf2
awk.xcframework.zip	dad5fe7a16a3f32343c53cb22d9a28a092e9ca6e8beb0faea4aae2c15359e8db
curl_ios.xcframework.zip	168bf3b37d8c14d0915049ea97a3d46518d855df488da986b876fc09df50af9f
files.xcframework.zip	7494be7319ef73271e2210e8ecf2ea2b134a35edb5ed921b9ca64c3586d158f3
shell.xcframework.zip	898d61af490747ccc1f581504c071db7508c816297985f9022cc6f2f21d19673
ssh_cmd.xcframework.zip	78d1b7c14c9447465cb49f1defd195e62dd77a4e4e2bc6762d8363754e2eee40
tar.xcframework.zip	1b8eb72a7e38714aa265441dc28ff1963b13990f67c660b9b058fffad11a4264
text.xcframework.zip	fcde883ff2d8f7d1cc43e9d4a80f01df8ab8d6e42515c4492f2fcc7a05b79afa

*/
