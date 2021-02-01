// use it from root folder:
// `swift run --package-path xcfs build [all, awk, tar, ios_system, ...]`

import FMake
import class Foundation.ProcessInfo

OutputLevel.default = .error

// TODO: We can add more platforms here
let platforms: [Platform] = [.iPhoneOS, .iPhoneSimulator, .Catalyst]

let allSchemes = [
    "ios_system",
    "awk",
    "curl_ios", 
    "files",
    "shell",
    "ssh_cmd",
    "tar",
    "text",
    ]

let args = ProcessInfo.processInfo.arguments 

var schemes: [String] 
if args.count > 1 && args[1] != "all" {
    schemes = args[1].components(separatedBy: ",")
} else {
    schemes = allSchemes 
}

var checksums: [[String?]] = []

for scheme in schemes {
    try xcxcf(
        dirPath: ".build",
        project: "ios_system",
        scheme: scheme,
        platforms: platforms.map { ($0, excludedArchs: []) }
    )

    try cd(".build") {
        let zip = "\(scheme).xcframework.zip"
        try sh("zip -r \(zip) \(scheme).xcframework")
        let chksum = try sha(path: zip)
        checksums.append([zip, chksum])
    }
}

var releaseNotes =
"""
Release notes:

\( checksums.markdown(headers: "File", "SHA 256") )

"""

try write(content: releaseNotes, atPath: ".build/release.md")

var package = 
"""
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

"""

for sum in checksums {
    let checksum = sum[1]!
    let fileName = sum[0]!
    let components = fileName.components(separatedBy:".")
    package += 
"""
        .binaryTarget(
            name: \"\(components[0])\",
            url: \"https://github.com/holzschu/ios_system/releases/download/v2.7.0/\(fileName)\",
            checksum: \"\(checksum)\",
        ),

"""
}
package += 
"""
        .binaryTarget(
            name: \"mandoc\",
            url: \"https://github.com/holzschu/ios_system/releases/download/2.7/mandoc.xcframework.zip\",
            checksum: \"428eadde2515ad58ede9943a54e0bd56f8cd2980cf89a7b1762c7f36594737f5\"
        )
    ]
)
"""

try write(content: package, atPath: "Package.swift")


