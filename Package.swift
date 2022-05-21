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
            checksum: "635fc346304416f05f94a61ded08a2a5792f5072081eca7c142834326366d4d0"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/awk.xcframework.zip",
            checksum: "d8fc59849698f9b0b43b5fa77d7d38410ec95482965e3a11afe03e6bebd06b88"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/curl_ios.xcframework.zip",
            checksum: "c07f2fca448a1cc23ba98bd979962a44587b4017508e101e1f7dcb4d0ca27b60"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/files.xcframework.zip",
            checksum: "c24641cf21f710d6db0832399e261c01b3504caf86ff6d13dcf0dcbaa1dd1172"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/shell.xcframework.zip",
            checksum: "cbd1a7675990777cef0d19c85295915f9d5af4430d1c7c631322d6e19495b148"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/ssh_cmd.xcframework.zip",
            checksum: "67174120060604888ee15c7b5f71686b671d80224f1cd9576f8d24381ed96759"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/tar.xcframework.zip",
            checksum: "e5e1ca866576d291a75b9f8ae18cdf215a6b70efde3144e7a0905488b0d42dc5"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.0/text.xcframework.zip",
            checksum: "c832c4e6b234c297526f2e16cfbf197da5be332dc69a3bdf452e135f8c33a77c"
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
ios_system.xcframework.zip	635fc346304416f05f94a61ded08a2a5792f5072081eca7c142834326366d4d0
awk.xcframework.zip	d8fc59849698f9b0b43b5fa77d7d38410ec95482965e3a11afe03e6bebd06b88
curl_ios.xcframework.zip	c07f2fca448a1cc23ba98bd979962a44587b4017508e101e1f7dcb4d0ca27b60
files.xcframework.zip	c24641cf21f710d6db0832399e261c01b3504caf86ff6d13dcf0dcbaa1dd1172
shell.xcframework.zip	cbd1a7675990777cef0d19c85295915f9d5af4430d1c7c631322d6e19495b148
ssh_cmd.xcframework.zip	67174120060604888ee15c7b5f71686b671d80224f1cd9576f8d24381ed96759
tar.xcframework.zip	e5e1ca866576d291a75b9f8ae18cdf215a6b70efde3144e7a0905488b0d42dc5
text.xcframework.zip	c832c4e6b234c297526f2e16cfbf197da5be332dc69a3bdf452e135f8c33a77c
*/
