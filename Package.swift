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
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/ios_system.xcframework.zip",
            checksum: "f7da5f7643a5d218712a628dd03f417e964e9a797e7db8be76d1b12bc7fb64be"
        ),
        .binaryTarget(
            name: "awk",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/awk.xcframework.zip",
            checksum: "32dc167823bffb8eabd657ff5bf63899bedbac07257edc5f73701b1d30ecb005"
        ),
        .binaryTarget(
            name: "curl_ios",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/curl_ios.xcframework.zip",
            checksum: "45a1a2cd33845d60771dcbe5201f3be650ccf3ac73b810ab5ae859f51356abcb"
        ),
        .binaryTarget(
            name: "files",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/files.xcframework.zip",
            checksum: "6dbe110482d15dc842dcb10bce1fe0a6a8d779843881eeffebd8c497b98e4f3c"
        ),
        .binaryTarget(
            name: "shell",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/shell.xcframework.zip",
            checksum: "1d559902bc615491e836671c8932af668f5a984aa49c55f71598960f7170d49c"
        ),
        .binaryTarget(
            name: "ssh_cmd",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/ssh_cmd.xcframework.zip",
            checksum: "ec2de9ee4eab9ef74ff2c88830bd129fa5977e43af42e64379f743d58446ba9b"
        ),
        .binaryTarget(
            name: "tar",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/tar.xcframework.zip",
            checksum: "45beadec61532e59ea431a8cde6c43767d309521b88d8a9d388f561d8b54caef"
        ),
        .binaryTarget(
            name: "text",
            url: "https://github.com/holzschu/ios_system/releases/download/v2.9.0/text.xcframework.zip",
            checksum: "3ea15f4ba15ffaa4c54873e7e660e9d9c7dafafdd43037d81c6747029c260371"
        ),
        // Other frameworks (no auto-build, so still at .../2.7/...)
        .binaryTarget(
            name: "mandoc",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip",
            checksum: "428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5"
        ),
        .binaryTarget(
            name: "perl",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/perl.xcframework.zip",
            checksum: "76c9b42b86ecbf65bf97d8d624fef317d505cae1a852818dc014c47785698872"
        ),
        .binaryTarget(
            name: "perlA",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/perlA.xcframework.zip",
            checksum: "b3d4cbd2d7dcc9df484c78acf5a9d37b9fdc8a28126fac435252fcd39dc0e6b7"
        ),
        .binaryTarget(
            name: "perlB",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/perlB.xcframework.zip",
            checksum: "67266f5278203f9ff7f080502e2095bd7a4e3d12b645a63a34d03d3e89c41131"
        ),
        .binaryTarget(
            name: "make",
            url: "https://github.com/holzschu/ios_system/releases/download/2.7/make.xcframework.zip",
            checksum: "397bc5bb13a6e349d0f72d508eb5edc46afb4547e99ab298f034ff6f0e3bfdb0"
        )        
    ]
)
/* checksums computed by github action, from https://github.com/holzschu/ios_system/releases/tag/v2.9.0 

ios_system.xcframework.zip	4f8ff7fba7a053d8cbd79abb505c2c71c0c9756d5eea64e845dee6f0946ea032
awk.xcframework.zip	cea938659311902471d64e5345294780d364f20f983ae701ddd52870afb0bceb
curl_ios.xcframework.zip	d21c43012a1966109f05a1f0c45bbcd74102204d9025ee243f4c0b31ae3651a7
files.xcframework.zip	2c6a028702519e823481310676407c6525f652db7e9bfdb84680bfc89263e0c8
shell.xcframework.zip	9af7f9d87e1bc1e26ff7c076959ee08a2d6b6584b56bbf772bcdbe43563bdb10
ssh_cmd.xcframework.zip	a3f19cd39b4ecb8e4f0983c4cbd78febc52a05e547ea4bdc85ddf74c2789b3ee
tar.xcframework.zip	13a188649adcb25ca483dcc35b4fd91538ba9629dd15e845cf7bac28f84d7526
text.xcframework.zip	c56d164d7c0fd37d88f265fbd2aca47cd21dc42db536af33a1a469660794ad98*/
