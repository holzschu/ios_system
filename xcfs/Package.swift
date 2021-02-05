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
            url: "https://github.com/blinksh/libssh2-apple/releases/download/v1.9.0/libssh2-static.xcframework.zip",
            checksum: "bcf240b14e5b0d982bde81419dbdf45d9155aea7401669f0c4bfd74db976d50a"
        ),
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/blinksh/openssl-apple/releases/download/v1.1.1i/openssl-static.xcframework.zip",
            checksum: "6ab47a85acb5d70318877b11bf38b9154b25faab3c78cbade384dc23d870bf34"
        ),

        .target(
            name: "build",
            dependencies: ["FMake"]
        ),
    ]
)
