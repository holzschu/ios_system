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
            checksum: "e469f7a94f1c02db596520ccf7452b17ebda65b67745f44dbc0d1919551bb597"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "ebb087ecb105c7ad0045e63109e7652a778a7af27d06ad4905256ed7cac4d6f2"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "c148b317d71fd065ff2abadd2b60323ab8765f1231f55707a242c9a15bb41c5e"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "5785c9b362405a3e300b5b052eb3f7bcfd90fbf84fdc1cff65d65bff2e4f15e3"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "7801d47ffb7d1454ffc10827c24397f913329e59f914c1e5cc9b3005ab28e0aa"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "6c38126bb2f5168d764484f158b764462ce2e8df36342c380909e851747c6ba7"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "b85b09e845f86661c7ea7f87ddeab0f2329ee92a210984283c6267d1831d2b89"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "31574b610cddfb457b159f1a6147b5f716c2f03a6d698264030429fd11ee63b9"
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
e469f7a94f1c02db596520ccf7452b17ebda65b67745f44dbc0d1919551bb597
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
ebb087ecb105c7ad0045e63109e7652a778a7af27d06ad4905256ed7cac4d6f2
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
c148b317d71fd065ff2abadd2b60323ab8765f1231f55707a242c9a15bb41c5e
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
5785c9b362405a3e300b5b052eb3f7bcfd90fbf84fdc1cff65d65bff2e4f15e3
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
7801d47ffb7d1454ffc10827c24397f913329e59f914c1e5cc9b3005ab28e0aa
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
6c38126bb2f5168d764484f158b764462ce2e8df36342c380909e851747c6ba7
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
b85b09e845f86661c7ea7f87ddeab0f2329ee92a210984283c6267d1831d2b89
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
31574b610cddfb457b159f1a6147b5f716c2f03a6d698264030429fd11ee63b9
*/
