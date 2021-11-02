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
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/ios_system.xcframework.zip",
            checksum: "66f4a5e696e29f3c70e8bab3a3e8c5f5a0bda48ab102e9db98a90db93b0981ea"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/awk.xcframework.zip",
            checksum: "d0ac9d6d98b8129c8b392a337c7d5e8289cdbdf9be3d5e6a5376891489c520a1"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/curl_ios.xcframework.zip",
            checksum: "8281e5b74ce6c4f6132415172cc806d097ba283048eb0882d14e1485ec49dade"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/files.xcframework.zip",
            checksum: "8296849e51ee9ddbb3796a1a87bb3a411cfdabd827d48bd5713fbfb3333d9862"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/shell.xcframework.zip",
            checksum: "846651a205e9d781f1f71d3124b5cfca3edfa7722a6c11977ab9c6c73049a810"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/ssh_cmd.xcframework.zip",
            checksum: "9b57b07d4e552f30f7127843860defe4e8edbad8c0b5f2e4c7e99399713b87e6"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/tar.xcframework.zip",
            checksum: "f5769e81aa15730cc041a7d95a8a8b549888633b2649b4f0adc20b437c25fb4d"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/text.xcframework.zip",
            checksum: "bd594ed4bbc67cf9c9393e360a35a35dd9674a4be0d460622221935ea7c76eb2"
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
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v3.0.0 
ios_system.xcframework.zip	66f4a5e696e29f3c70e8bab3a3e8c5f5a0bda48ab102e9db98a90db93b0981ea
awk.xcframework.zip	d0ac9d6d98b8129c8b392a337c7d5e8289cdbdf9be3d5e6a5376891489c520a1
curl_ios.xcframework.zip	8281e5b74ce6c4f6132415172cc806d097ba283048eb0882d14e1485ec49dade
files.xcframework.zip	8296849e51ee9ddbb3796a1a87bb3a411cfdabd827d48bd5713fbfb3333d9862
shell.xcframework.zip	846651a205e9d781f1f71d3124b5cfca3edfa7722a6c11977ab9c6c73049a810
ssh_cmd.xcframework.zip	9b57b07d4e552f30f7127843860defe4e8edbad8c0b5f2e4c7e99399713b87e6
tar.xcframework.zip	f5769e81aa15730cc041a7d95a8a8b549888633b2649b4f0adc20b437c25fb4d
text.xcframework.zip	bd594ed4bbc67cf9c9393e360a35a35dd9674a4be0d460622221935ea7c76eb2
*/
