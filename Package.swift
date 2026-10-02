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
            checksum: "d2deb9f77dff839e069f21efdb11f16864a8173e33956cd1b4d174a76f1b0e99"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/awk.xcframework.zip",
            checksum: "560f786c77d487a482de7fcd1caa4736a95979783483685d53a8503a7514e53f"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/curl_ios.xcframework.zip",
            checksum: "62b153f4536987f9fd50852b29400dd083f07fb7e3155a44e8d181a25a44dcf4"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/files.xcframework.zip",
            checksum: "4e36aeb7242592a848a7ee3b74109dc45f63e16fa9fa4d07bc80026ec30897e3"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/shell.xcframework.zip",
            checksum: "bdace8281617602f1f0da7c90d933388085e31de9f31964467671f212966f76a"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/ssh_cmd.xcframework.zip",
            checksum: "fbc3ed1e2e0b62e9631f660b42a8739aee90b2643812987bb2e66c10032825fb"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/tar.xcframework.zip",
            checksum: "a44176ba8a016630fcf75dc9e2a961a17b5433196fff19d0a270a8b23d550f93"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v3.0.6/text.xcframework.zip",
            checksum: "93ed6410a972b3dd9dfa2ff93e4260f2b5401168c52c78ae1bb08f16d6b74533"
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
ios_system.xcframework.zip	d2deb9f77dff839e069f21efdb11f16864a8173e33956cd1b4d174a76f1b0e99
awk.xcframework.zip	560f786c77d487a482de7fcd1caa4736a95979783483685d53a8503a7514e53f
curl_ios.xcframework.zip	62b153f4536987f9fd50852b29400dd083f07fb7e3155a44e8d181a25a44dcf4
files.xcframework.zip	4e36aeb7242592a848a7ee3b74109dc45f63e16fa9fa4d07bc80026ec30897e3
shell.xcframework.zip	bdace8281617602f1f0da7c90d933388085e31de9f31964467671f212966f76a
ssh_cmd.xcframework.zip	fbc3ed1e2e0b62e9631f660b42a8739aee90b2643812987bb2e66c10032825fb
ssh_cmdA.xcframework.zip	2211ae73b7dcc0a1de8f260d9d776da89e12ca0bf565e88d9ef1c3373ac2f6b6
ssh_agent.xcframework.zip	2a689e727d925444cf2a686d8bdee9b9f0e8875adc2f85851c7795b85961b92f
sshd.xcframework.zip	1bd145b92ec01ab68c32dc7082337744b2068c4e3154123466dd14c99efb3eb3
tar.xcframework.zip	a44176ba8a016630fcf75dc9e2a961a17b5433196fff19d0a270a8b23d550f93
text.xcframework.zip	93ed6410a972b3dd9dfa2ff93e4260f2b5401168c52c78ae1bb08f16d6b74533
*/
