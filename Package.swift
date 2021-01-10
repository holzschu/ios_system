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
            checksum: "8104fc43f78adee777b941889da06be716751a1cae12cae3c7e100a50d092ba9"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "8f709d5556d8ba05f2ea96f96365943128fb2c88712ebae87a4e65baae778d2b"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "1fd9d839c64c79629a234312088a772cd564865f3047d0ac13859f7cd76d49b1"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "7f22beafc8f2c93b939bdad3df5700c482e821654a25643f44d3834f46714fea"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "c42744e04bc691d3fcf0da83a39c820b3cab8ae59859f06b31d1a33c992f3836"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "d8c43acbb41f70064b8793eb7ae9e9a7c5bac2511a4916ba0f9419585115f03d"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "402e8058602dd7b8f29792feb3f2cb0fef03e7e6b6499bfde5bd6ce0ff4ab8c4"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "f0c7019ced4f6da153bbb342211c358fc8917691f92bf5b3410132904f096f46"
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
8104fc43f78adee777b941889da06be716751a1cae12cae3c7e100a50d092ba9
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
8f709d5556d8ba05f2ea96f96365943128fb2c88712ebae87a4e65baae778d2b
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
1fd9d839c64c79629a234312088a772cd564865f3047d0ac13859f7cd76d49b1
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
7f22beafc8f2c93b939bdad3df5700c482e821654a25643f44d3834f46714fea
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
c42744e04bc691d3fcf0da83a39c820b3cab8ae59859f06b31d1a33c992f3836
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
d8c43acbb41f70064b8793eb7ae9e9a7c5bac2511a4916ba0f9419585115f03d
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
402e8058602dd7b8f29792feb3f2cb0fef03e7e6b6499bfde5bd6ce0ff4ab8c4
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
f0c7019ced4f6da153bbb342211c358fc8917691f92bf5b3410132904f096f46
*/

