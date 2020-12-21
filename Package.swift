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
            checksum: "a497cffe41326a46bc6e1b103bfe241ab21f498af410660dc6d61272e1602600"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "c940ffa546ca9dacb9bcab1e02118b55712e7202f173d584380f4643e165d078"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "9c434acd708b3031238561afecd2869efedd1aa1d3685065fde417c14b03e078"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "3e1c2f99bf722f020e19aabfd7343b8bb710b93233f5fb772a5495eb29f54038"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "f995eeec8650e97e729a6dd4685cd9687058eccf85630e6822f395e2149064f3"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "fbdbd79a9ef1d66e95facb2392268fbaf1036e269a6c136e0c4635efc23e84bc"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "11526cb4c27060ccc5ed24db4938d669ccf2da739023f845df9d249172a7ac4b"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "85d3adb5fcb9f52021c479dea555efbc9835c60a1ce7e946b941cd4a25d6576f"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* 
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/awk.xcframework
a497cffe41326a46bc6e1b103bfe241ab21f498af410660dc6d61272e1602600
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
c940ffa546ca9dacb9bcab1e02118b55712e7202f173d584380f4643e165d078
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
9c434acd708b3031238561afecd2869efedd1aa1d3685065fde417c14b03e078
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
3e1c2f99bf722f020e19aabfd7343b8bb710b93233f5fb772a5495eb29f54038
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
f995eeec8650e97e729a6dd4685cd9687058eccf85630e6822f395e2149064f3
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
fbdbd79a9ef1d66e95facb2392268fbaf1036e269a6c136e0c4635efc23e84bc
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
11526cb4c27060ccc5ed24db4938d669ccf2da739023f845df9d249172a7ac4b
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
85d3adb5fcb9f52021c479dea555efbc9835c60a1ce7e946b941cd4a25d6576f
*/

