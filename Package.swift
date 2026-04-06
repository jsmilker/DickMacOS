// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "whisper-dictation",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "whisper-dictation", targets: ["WhisperDictation"])
    ],
    targets: [
        .executableTarget(
            name: "WhisperDictation",
            path: "Sources/WhisperDictation"
        )
    ]
)
