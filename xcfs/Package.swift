// swift-tools-version:5.3
import PackageDescription

_ = Package(
    name: "xcfs",
    platforms: [.macOS("11")],
    dependencies: [
        .package(url: "https://github.com/yury/FMake", from: "0.0.16")
    ],
    
    targets: [
        // curl_ios
        .binaryTarget(
            name: "libssh2",
            url: "https://github.com/blinksh/libssh2-apple/releases/download/v1.9.0/libssh2-static.xcframework.zip",
            checksum: "6a14c161ee389ef64dfd4f13eedbdf8628bbe430d686a08c4bf30a6484f07dcb"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/blinksh/openssl-apple/releases/download/v1.1.1k/openssl-static.xcframework.zip",
            checksum: "cf969ea17dc0f5740eb0a55902a71cdf8464440c3dda4f3d55df3f8084a655ba"
        ),

        .target(
            name: "build",
            dependencies: ["FMake"]
        ),
    ]
)
