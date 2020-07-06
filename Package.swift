// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ios_system",
    // thread-local variables are only available with iOS 11+. This setting is required for compilation.
    platforms: [.iOS(.v11)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ios_system",
            type: .dynamic, 
            targets: ["ios_system"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        // binaryTargets will need the next version of Xcode. It will be great for libssh2/openssl.
        .target(
            name: "ios_system",
            dependencies: [],
            cSettings: [.headerSearchPath("..")]),
    ]
)

// cSettings or cxxSettings. Each have 3 options:
// cSettings: [ .define("ONLY_ACTIVE_ARCH", to: "NO"), .headerSearchPath(".."), .unsafeFlags([""])]),
// Files and the others will have to be a separate package.
// .library(
//     name: "files",
//     targets: ["files"]),
// .target(
//     name: "files",
//     dependencies: ["ios_system"],
//     exclude: ["gzip/unbzip2.c", "gzip/zuncompress.c", "gzip/unpack.c"],
//     cSettings: [.define("COLORLS", to: "1"), .headerSearchPath(".."), .unsafeFlags(["-Wshorten-64-to-32 // -Wno-ambiguous-macro -Wunused-const-variable -Wincompatible-pointer-types-discards-qualifiers"])]),
