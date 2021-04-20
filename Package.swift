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
            checksum: "fb80aa558f9d94014ae90f85f7d032ad02ee29ffa7ad66128f873edc4c4fd680"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/awk.xcframework.zip",
            checksum: "2f5f1c1289ff4c5f3671e35368e9549d3847f9f13ef520b7b193cfe6afb75cd3"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/curl_ios.xcframework.zip",
            checksum: "491a2a744e1d3e68b345ffc6bcad61abecd97e7535c4879c18d146ad334d21d4"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/files.xcframework.zip",
            checksum: "db8be9c3bbc1c96c7c10c5a6ae61c092c21d2a6ebe9f8529fefe684b820e1c2b"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/shell.xcframework.zip",
            checksum: "ecb0cfb8ef9f02602ae813e4c103729e25e8aba0026dd4bcbf3e916f1937478d"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/ssh_cmd.xcframework.zip",
            checksum: "31619db30627b9ab2525411cd328b19db9e906360a9c61ad8a7c1ea63efe0e8a"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/tar.xcframework.zip",
            checksum: "63413cc35859d91b4cf4925ab2bedf5fa1a664014b212a158f504c16223408a1"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.7.0/text.xcframework.zip",
            checksum: "9da87e34e0589ff91f185bd030c072cb642e76eda11a7e57cbe1102576d45b57"
        ),
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        )
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.8.0 

ios_system.xcframework.zip	fb80aa558f9d94014ae90f85f7d032ad02ee29ffa7ad66128f873edc4c4fd680
awk.xcframework.zip	2f5f1c1289ff4c5f3671e35368e9549d3847f9f13ef520b7b193cfe6afb75cd3
curl_ios.xcframework.zip	491a2a744e1d3e68b345ffc6bcad61abecd97e7535c4879c18d146ad334d21d4
files.xcframework.zip	db8be9c3bbc1c96c7c10c5a6ae61c092c21d2a6ebe9f8529fefe684b820e1c2b
shell.xcframework.zip	ecb0cfb8ef9f02602ae813e4c103729e25e8aba0026dd4bcbf3e916f1937478d
ssh_cmd.xcframework.zip	31619db30627b9ab2525411cd328b19db9e906360a9c61ad8a7c1ea63efe0e8a
tar.xcframework.zip	63413cc35859d91b4cf4925ab2bedf5fa1a664014b212a158f504c16223408a1
text.xcframework.zip	9da87e34e0589ff91f185bd030c072cb642e76eda11a7e57cbe1102576d45b57
*/
