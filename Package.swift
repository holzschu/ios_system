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
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/ios_system.xcframework.zip",
            checksum: "6973c1c14a66cdc110a5be7d62991af4546124bd0d9773b5391694b3a93a5be0"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/awk.xcframework.zip",
            checksum: "6898b01913261eee194edcb464212d4af6bc33355b1e286bbbd17f3f878c1706"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/curl_ios.xcframework.zip",
            checksum: "2a0020ce4904ea71e83c8daa86e99515b322981abc8ab2092b700661bcc880cd"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/files.xcframework.zip",
            checksum: "02d6522f5e1adc3b472f7aaa53910f049e6c5829e07c7e3005cf2a0d5f9f423a"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/shell.xcframework.zip",
            checksum: "78d71828b89c83741a8f7e857f0d065da72952558fd7deb806f5748c3801fd95"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/ssh_cmd.xcframework.zip",
            checksum: "190597a3ec09d6bc250e31caa8b08ecc2b6f27ecbd6b24fda84065ccd2be309e"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/tar.xcframework.zip",
            checksum: "9bf482b29ea95bc643bfaa06b249394afed188e40482db055625f4928ffedc48"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.4/text.xcframework.zip",
            checksum: "2450f309d0793490136a24f9af02c42fb712b327571cb44312fe330e87a156f2"
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
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v3.0.1 
ios_system.xcframework.zip	f8e1364037de546809065ecdf804277fa7b95faffc32604e91ecb4de44d6294e
awk.xcframework.zip	73abc0d502eab50e6bbdd0e49b0cf592f3a85b3843c43de6d7f42c27cde9b953
curl_ios.xcframework.zip	7338fb9ae8094356c8cd523cfda9e4c60b52d710488432eb64cf57731b388dd2
files.xcframework.zip	d0643e2244009fc5279f1f969c6da47ca197b4e7c9dac27dea09ba0a5f1567d7
shell.xcframework.zip	876b709c1b76cbc1748d434fcbc2cea1aea2e281572e5fadc40244dd8a549757
ssh_cmd.xcframework.zip	342065209123f54c92eb78a0fbda579e61948443e5f60e41d8fe356a3fe8f2ff
tar.xcframework.zip	6ffe4ed265060f971df229dd1d2bff90e7bc78c80c50dcc3a0a633face440bc4
text.xcframework.zip	697bee697b509d0dc8acc156a7430f453c29878d8af273adfb8902643c70ea0f
*/
