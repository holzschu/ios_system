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
            checksum: "3ee67de6202a6b75c35ddf2583cc7b9a9d75a2a9bb80d3c8d7da5020a0e6360f",
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/awk.xcframework.zip",
            checksum: "656d5d74ebe11965b9fa70a30608c2f8cb76f0891d401daf4ba24fad526c4816",
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/curl_ios.xcframework.zip",
            checksum: "de642a49154c1d5212630abae160b50c2a5df3266ab30908e21f1297ee178c17",
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/files.xcframework.zip",
            checksum: "ee0fe0aeb1dc36a176fa4467bd7708a2b2978c6f65c233d71dc0eb6da8652713",
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/shell.xcframework.zip",
            checksum: "84f32ccfee3c2db82fefa4e9c54363d5448b7ff364f2774f16a57f1f12d25ec2",
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ssh_cmd.xcframework.zip",
            checksum: "bf23cf9f2405f6c0b2094616d8601ede2fbd31c8b1a7b35c3933fe4ec3bab64c",
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/tar.xcframework.zip",
            checksum: "ae9a1db7c4b85a715253a9fd5026b3a3d48784b18bdee6003c7011fd5c523edf",
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/text.xcframework.zip",
            checksum: "23365a4e98f4a6b773188759233215ee6057b4a31a12ad72c34a5a4108783e7f",
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)