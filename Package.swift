// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OCFlow",
    platforms: [.macOS(.v26)],
    dependencies: [
        // Parakeet TDT as CoreML on the Neural Engine. Optional at runtime — Apple's
        // SpeechTranscriber remains the default and needs no dependency at all.
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.15.6")
    ],
    targets: [
        // The dictionary is its own target so it can be tested directly against the
        // vectors in Tests/OCFlowDictionaryTests/dictionary-test-vectors.json.
        .target(
            name: "OCFlowDictionary",
            path: "Sources/OCFlowDictionary",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "OCFlow",
            dependencies: [
                "OCFlowDictionary",
                .product(name: "FluidAudio", package: "FluidAudio"),
            ],
            path: "Sources/OCFlow",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "OCFlowDictionaryTests",
            dependencies: ["OCFlowDictionary"],
            path: "Tests/OCFlowDictionaryTests",
            resources: [.copy("dictionary-test-vectors.json")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
