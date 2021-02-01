// swift-tools-version:5.3
import PackageDescription

_ = Package(
    name: "xcfs",
    platforms: [.macOS("11")],
    dependencies: [
        .package(url: "https://github.com/yury/FMake", from: "0.0.16")
    ],
    
    targets: [
        // ssh_cmd, curl_ios
        .binaryTarget(
            name: "libssh2",
            url: "https://github.com/yury/libssh2-apple/releases/download/v1.9.0/libssh2-dynamic.xcframework.zip",
            checksum: "07952e484eb511b1badb110c15d4621bb84ef98b28ea4d6e1d3a067d420806f5"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/yury/openssl-apple/releases/download/v1.1.1i/openssl-dynamic.xcframework.zip",
            checksum: "d07917d2db5480add458a7373bb469b2e46e9aba27ab0ebd3ddc8654df58e60f"
        ),

        .target(
            name: "build",
            dependencies: ["FMake"]
        ),
    ]
)
