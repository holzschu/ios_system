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
            checksum: "8cefda9d860a503f641063c0a03614162c502524a963e96b5d59e5648c5d5320"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/awk.xcframework.zip",
            checksum: "a26bf5bb6ddd911047c264dc67171f37070b148fe0a8d08d68dd18af1301eae6"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/curl_ios.xcframework.zip",
            checksum: "f1d61e4dbe052e3a7ed7cfd28fa8b8e6e88af4c61d35eafcd08f4549491462dd"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/files.xcframework.zip",
            checksum: "8a84a63201c5fd7c7553669ec5cae7d72144a4b77b844cccf867c09a4d0faa75"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/shell.xcframework.zip",
            checksum: "bb9c0f10c8e6a0f789d8f00a724346e20f751a199bbec0647fe2ec6d114a3b5c"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ssh_cmd.xcframework.zip",
            checksum: "59630037a71cd5be8b50901e39d606e7aff9f6e29899fc112fa1ff2fadd1325c"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/tar.xcframework.zip",
            checksum: "9da4984c1989b28105315a8dbe70922ac421692879b4425a2bf38b4537e3afcc"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/text.xcframework.zip",
            checksum: "9666c3cab41e274e6683c55e34bc1a35d87de4d0156a81567f86981a981134e9"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.7.0 

ios_system.xcframework.zip	8cefda9d860a503f641063c0a03614162c502524a963e96b5d59e5648c5d5320
awk.xcframework.zip	a26bf5bb6ddd911047c264dc67171f37070b148fe0a8d08d68dd18af1301eae6
curl_ios.xcframework.zip	f1d61e4dbe052e3a7ed7cfd28fa8b8e6e88af4c61d35eafcd08f4549491462dd
files.xcframework.zip	8a84a63201c5fd7c7553669ec5cae7d72144a4b77b844cccf867c09a4d0faa75
shell.xcframework.zip	bb9c0f10c8e6a0f789d8f00a724346e20f751a199bbec0647fe2ec6d114a3b5c
ssh_cmd.xcframework.zip	59630037a71cd5be8b50901e39d606e7aff9f6e29899fc112fa1ff2fadd1325c
tar.xcframework.zip	9da4984c1989b28105315a8dbe70922ac421692879b4425a2bf38b4537e3afcc
text.xcframework.zip	9666c3cab41e274e6683c55e34bc1a35d87de4d0156a81567f86981a981134e9

*/
