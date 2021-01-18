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
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/awk.xcframework.zip",
            checksum: "ec10b79bc6eb3086452652a0f2353a5040108244cf54f84e1beab9fa7e34b2b2"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/curl_ios.xcframework.zip",
            checksum: "5f3ab067d23561d97a89c6f324ef2bfe3f380cd55896ae273e3445a47851d62a"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/files.xcframework.zip",
            checksum: "86d556a468801e2d796ebc7ca7a11103d6ce239cb2e9479841151bcf84cc4599"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/ios_system.xcframework.zip",
            checksum: "e6cc2503613b6dd922cb90b380631fce63b9fa06ad0370e87cf5195bc51e2f9e"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/shell.xcframework.zip",
            checksum: "8bd32e5858b7f66946596b70f2530031dd31234ab5e0d010ef62cd769132b4a0"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/ssh_cmd.xcframework.zip",
            checksum: "0a5cc2073b58081bdd3020ebb6e67405d754ad77ed352288555732921c57546b"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/tar.xcframework.zip",
            checksum: "6bb35575c43f94ec1b79fe9caa6d757caefeeb250dd1472b9e81bc64d0476201"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/text.xcframework.zip",
            checksum: "3a263b420c0ba06fa9d00f1e21da3d8cfe0903d7a8e28b4d2b8ccfdbacbad76b"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* 
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/awk.xcframework
ec10b79bc6eb3086452652a0f2353a5040108244cf54f84e1beab9fa7e34b2b2
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
5f3ab067d23561d97a89c6f324ef2bfe3f380cd55896ae273e3445a47851d62a
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
86d556a468801e2d796ebc7ca7a11103d6ce239cb2e9479841151bcf84cc4599
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
8bcdeb9cfa870d38be34075e9ebe9abea30c07359fa9b94b732c487cf070963a
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
8bd32e5858b7f66946596b70f2530031dd31234ab5e0d010ef62cd769132b4a0
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
0a5cc2073b58081bdd3020ebb6e67405d754ad77ed352288555732921c57546b
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
6bb35575c43f94ec1b79fe9caa6d757caefeeb250dd1472b9e81bc64d0476201
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
3a263b420c0ba06fa9d00f1e21da3d8cfe0903d7a8e28b4d2b8ccfdbacbad76b
*/

