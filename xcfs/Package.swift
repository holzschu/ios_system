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
            url: "https://github.com/blinksh/libssh2-apple/releases/download/v1.9.0/libssh2-dynamic.xcframework.zip",
            checksum: "79b18673040a51e7c62259965c2310b5df2a686de83b9cc94c54db944621c32c"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/blinksh/openssl-apple/releases/download/v1.1.1i/openssl-dynamic.xcframework.zip",
            checksum: "7f7e7cf7a1717dde6fdc71ef62c24e782f3c0ca1a2621e9376699362da990993"
        ),

        .target(
            name: "build",
            dependencies: ["FMake"]
        ),
    ]
)
