// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DickMacOS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "dickmacos", targets: ["DickMacOS"])
    ],
    targets: [
        .executableTarget(
            name: "DickMacOS",
            path: "Sources/DickMacOS"
        )
    ]
)
