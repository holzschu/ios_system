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
            checksum: "d288d4f86c6d7ee5d19c16492f57c5511ba94a690e3d12ce2cdc95478c728adf"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/curl_ios.xcframework.zip",
            checksum: "1116f7bb1e8ab0f6a997d74d228569f1b337beca802a4166110a9283eff5a87c"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/files.xcframework.zip",
            checksum: "ae6a9a485efb0d7d4e4461ddd76ba9295aef73ca6ec67d7d4a409bef4b281494"
        ),
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ios_system.xcframework.zip",
            checksum: "a8709879536e38fca4bed4471f286809d605f9c80c5ec4064aca8ad52f1a9263"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/shell.xcframework.zip",
            checksum: "5ceb72592574117df2a1e2d0f17be245c72b7e65adf4568d7407cecf063984fe"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/ssh_cmd.xcframework.zip",
            checksum: "26cb57d0962900482efb286bc6f79d59b3ae4d6cfbac53854766d4123f745fc9"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/tar.xcframework.zip",
            checksum: "e02b9d81dd1bcca47adb845581196f05aae4ce0f2fe738cf07bc1933dcd16865"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/2.6/text.xcframework.zip",
            checksum: "7c06f23542511513e8e2c75b3b9def4ed8a2cbafdd101a00a72026c588980123"
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
d288d4f86c6d7ee5d19c16492f57c5511ba94a690e3d12ce2cdc95478c728adf
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/curl_ios.xcframework
1116f7bb1e8ab0f6a997d74d228569f1b337beca802a4166110a9283eff5a87c
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/files.xcframework
ae6a9a485efb0d7d4e4461ddd76ba9295aef73ca6ec67d7d4a409bef4b281494
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ios_system.xcframework
a8709879536e38fca4bed4471f286809d605f9c80c5ec4064aca8ad52f1a9263
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/shell.xcframework
5ceb72592574117df2a1e2d0f17be245c72b7e65adf4568d7407cecf063984fe
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/ssh_cmd.xcframework
26cb57d0962900482efb286bc6f79d59b3ae4d6cfbac53854766d4123f745fc9
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/tar.xcframework
e02b9d81dd1bcca47adb845581196f05aae4ce0f2fe738cf07bc1933dcd16865
xcframework successfully written out to: /Users/holzschu/src/Xcode_iPad/ios_system/text.xcframework
7c06f23542511513e8e2c75b3b9def4ed8a2cbafdd101a00a72026c588980123
*/

