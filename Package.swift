// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ios_system",
    products: [
        .library(name: "ios_system", targets: ["ios_system", "awk", "curl_ios", "files", "shell", "ssh_cmd", "tar", "text", "mandoc", "perl", "perlA", "perlB"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "ios_system",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/ios_system.xcframework.zip",
            checksum: "6022e36472dabebf6be96d2ce4de9da2609dc3f00d26e64359f68241b85bf1e3"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/awk.xcframework.zip",
            checksum: "8f8268507c55d4e1caa75726c117b43a99691656da5f832cc72bfe3dce274e1d"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/curl_ios.xcframework.zip",
            checksum: "8ccda25c81f13ec6a1324dfbf9f09fe8d4da5f8296a8d3dec417a61e30483480"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/files.xcframework.zip",
            checksum: "598ae49b3a3a322e0d2a87e7c3cb3fa1c29ddeea84c39c0f30c9dfb468d50c7a"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/shell.xcframework.zip",
            checksum: "2e77d2cf9692f6460ba760b72cde6f7106e7ff5e48ebc76feafb3300cff52db8"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/ssh_cmd.xcframework.zip",
            checksum: "079c3e702d3530a3edbd828b3fd57a843082b507598bbe3be963aeef34450371"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/tar.xcframework.zip",
            checksum: "75ce32b7e4673924a010f9602390d28dbcc038f43f6cbed8b89e793f8135a201"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/text.xcframework.zip",
            checksum: "1b17b7d81b86770136d67570e62701663df4f6bebd5b18b5dea78f791d03c7fa"
        ),
        // Other frameworks (no auto-build, so still at .../2.7/...)
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "02b952191ec311fe04df0001e85e8812f68473b6616eaed4a03c045aed111a43"
        ),
        .binaryTarget(
            name: "perl",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/perl.xcframework.zip",
            checksum: "7f470ea838139a4aaa4dee8f3f0505c3a5d8769a54fcda9336b5d60b60abec62"
        ),
        .binaryTarget(
            name: "perlA",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/perlA.xcframework.zip",
            checksum: "8015a11ab6fa15aeb16c417b229d10b28e28e756c533b7f3faf3b6029b83dc49"
        ),
        .binaryTarget(
            name: "perlB",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/perlB.xcframework.zip",
            checksum: "fd2ca9fb3853aba1d6744c03db6cc88783d170ed0c119bd97e8ebe6fa3ec30b3"
        ),
        .binaryTarget(
            name: "make",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/make.xcframework.zip",
            checksum: "942a05e1cd165c4fb955b274e08a1069e388ae6706770e617e47ce55927b2b2f"
        )
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.9.0 
*/
