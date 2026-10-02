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
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/ios_system.xcframework.zip",
            checksum: "c9c6dc4cde45cc271ccc8bd0553ce4d3149eced1f0ee3d9e0ce01885d93526e6"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/awk.xcframework.zip",
            checksum: "675d3b2e3b5ba60ae1a727528b2cf5e11eda262d404c1e9708dc7e061898df86"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/curl_ios.xcframework.zip",
            checksum: "f9a74e005115aad3b51dd8daa2fb4727eb8425018805d7dd2973e598af65f968"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/files.xcframework.zip",
            checksum: "5db63958f686cc79f107bafd0d50feff32fb2b64d0dd976478c5dd405f7600b0"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/shell.xcframework.zip",
            checksum: "89da3b8bd7f83e42a2311aeac54c38acc7a2f9c2fc0d0d27f75897b393cdfec2"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/ssh_cmd.xcframework.zip",
            checksum: "fbe01fb1cf471cbdc4893ddd6e88ff1def7480cab40a6dfe3ea1626d4b35d8c4"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/tar.xcframework.zip",
            checksum: "74146ae19720d3d885d181bce4be2b6b92f11d306a47aa07486bf0dd35fc8f68"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/text.xcframework.zip",
            checksum: "9eef16c23ddaa03d5f28ce2183737b1dbdcfb06e6dc46035a404d9e0f3828604"
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


/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v3.0.6 
ios_system.xcframework.zip	c9c6dc4cde45cc271ccc8bd0553ce4d3149eced1f0ee3d9e0ce01885d93526e6
awk.xcframework.zip	675d3b2e3b5ba60ae1a727528b2cf5e11eda262d404c1e9708dc7e061898df86
curl_ios.xcframework.zip	f9a74e005115aad3b51dd8daa2fb4727eb8425018805d7dd2973e598af65f968
files.xcframework.zip	5db63958f686cc79f107bafd0d50feff32fb2b64d0dd976478c5dd405f7600b0
shell.xcframework.zip	89da3b8bd7f83e42a2311aeac54c38acc7a2f9c2fc0d0d27f75897b393cdfec2
ssh_cmd.xcframework.zip	fbe01fb1cf471cbdc4893ddd6e88ff1def7480cab40a6dfe3ea1626d4b35d8c4
ssh_cmdA.xcframework.zip	ae90f138db5bdd8943499e6217a0286834d9c844ea0e9e8289f09b00bd438409
ssh_agent.xcframework.zip	c5868579c712a09609d023a8b3695bd977a3ef7aadb1bbdef59ccaa1b334c029
sshd.xcframework.zip	8d9fb7c0da94bf29afbc683e66afc153b90294bcc929c0b4dc663cd7471548ad
tar.xcframework.zip	74146ae19720d3d885d181bce4be2b6b92f11d306a47aa07486bf0dd35fc8f68
text.xcframework.zip	9eef16c23ddaa03d5f28ce2183737b1dbdcfb06e6dc46035a404d9e0f3828604*/
