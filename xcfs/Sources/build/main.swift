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
    "ssh_cmdA",
    "ssh_agent",
    "sshd",
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
        try sh("zip --symlinks -r \(zip) \(scheme).xcframework")
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

