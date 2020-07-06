// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tar",
    // thread-local variables are only available with iOS 11+. This setting is required for compilation.
    platforms: [.iOS(.v11)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "tar",
            targets: ["tar"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // Depends on the local package, ios_system:
        .package(path: "../ios_system")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "tar",
            dependencies: ["ios_system"],
            exclude: [],
            cSettings: [.define("HAVE_CONFIG_H", to: "1"),
                        .headerSearchPath("../"),
                        .headerSearchPath("./"),
                        .headerSearchPath("./libarchive/"),
                        .headerSearchPath("./libarchive_fe/"),
                        .unsafeFlags([""])],
            linkerSettings: [.linkedLibrary("libz2"), .linkedLibrary("libxml2")]
        ),
    ]
)
