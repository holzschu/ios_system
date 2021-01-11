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
            checksum: "ac9898b0060bd6de8e418da8bfca68dc15ad4a1d5e45e68019020d31c279f9a0"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "42e3d6aa57f2570428627a273c3360001fabf09c08662d731373d5567170c98a"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "f0264d45650baf36812fcc20b83cb2b3f17bdded1782b373ba75614ecec97706"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "f5acf57c826bc471df551b260b659d2483f7ff0f13ed3b1e7488f1ef948a69ef"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "eaafa0c53d376c5b85aad4f91faa13418e5d4231bd4f2e24b6c5258f04835677"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "c4103a95f86be83ca93af70e7ddb2df0c1908d7dd8a5e9e1cf144c7c35354581"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "ea5b7111a73c947d003aa488bbca3d807d5326adb14282fa82c48a08be2ff6b1"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "d9db1a14532ec452c9a0d82504917f6c54edca6aa080fcc3bc587577696ee379"
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
ac9898b0060bd6de8e418da8bfca68dc15ad4a1d5e45e68019020d31c279f9a0
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
42e3d6aa57f2570428627a273c3360001fabf09c08662d731373d5567170c98a
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
f0264d45650baf36812fcc20b83cb2b3f17bdded1782b373ba75614ecec97706
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
f5acf57c826bc471df551b260b659d2483f7ff0f13ed3b1e7488f1ef948a69ef
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
eaafa0c53d376c5b85aad4f91faa13418e5d4231bd4f2e24b6c5258f04835677
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
c4103a95f86be83ca93af70e7ddb2df0c1908d7dd8a5e9e1cf144c7c35354581
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
ea5b7111a73c947d003aa488bbca3d807d5326adb14282fa82c48a08be2ff6b1
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
d9db1a14532ec452c9a0d82504917f6c54edca6aa080fcc3bc587577696ee379
*/

