// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Nicotine",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Nicotine", targets: ["Nicotine"])
    ],
    targets: [
        .executableTarget(
            name: "Nicotine",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
