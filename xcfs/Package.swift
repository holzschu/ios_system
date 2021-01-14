// swift-tools-version:5.3
import PackageDescription

_ = Package(
    name: "deps",
    platforms: [.macOS("11")],
    dependencies: [
        // .package(path: "../../libssh2-spm"),
        // .package(path: "../../openssl-spm"),
        .package(url: "https://github.com/yury/FMake", from: "0.0.8")
    ],
    
    targets: [
        .binaryTarget(
            name: "libssh2",
            url: "https://github.com/holzschu/libssh2-for-iOS/releases/download/v1.2/libssh2.xcframework.zip",
            checksum: "47015c95d80a6e6b222698682ea09db1d97f9e7c4936481b4a53fae68fdc33f5"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/holzschu/libssh2-for-iOS/releases/download/v1.2/openssl.xcframework.zip",
            checksum: "b13ab2943ebe5ced0048fb917dd36dd9756ab20da9c50b1f667eebac39c689ed"
        ),
        // ssh_cmd, curl_ios
        /*
        .binaryTarget(
            name: "libssh2",
            url: "https://github.com/yury/libssh2-apple/releases/download/v1.9.0/libssh2-dynamic.xcframework.zip",
            checksum: "07952e484eb511b1badb110c15d4621bb84ef98b28ea4d6e1d3a067d420806f5"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/yury/openssl-apple/releases/download/v1.1.1i/openssl-dynamic.xcframework.zip",
            checksum: "fcb0fc351299692a1d1de6206f30a3145f27854e71dc1fea9286103237cbd3a9"
        ),
        */
        .target(
            name: "build",
            dependencies: ["FMake"]
        ),
    ]
)