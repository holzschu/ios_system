// swift-tools-version:5.3
import PackageDescription

_ = Package(
    name: "xcfs",
    platforms: [.macOS("11")],
    dependencies: [
        .package(url: "https://github.com/holzschu/FMake", from: "0.0.19")
    ],
    
    targets: [
        // ssh2:
        .binaryTarget(
            name: "libssh2",
            url: "https://github.com/holzschu/libssh2-apple/releases/download/v1.11.0/libssh2-dynamic.xcframework.zip",
            checksum: "cacfe1789b197b727119f7e32f561eaf9acc27bf38cd19975b74fce107f868a6"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/holzschu/openssl-apple/releases/download/v1.1.1w/openssl-dynamic.xcframework.zip",
            checksum: "329e8317cf9bee8e138da5d032330a7a1bd2473cf44c9c083cb2f0636abb8b80"
        ),
        .target(
            name: "build",
            dependencies: ["FMake"]
        ),
    ]
)
