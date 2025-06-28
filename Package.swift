// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "brightness-cli",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // DDC library for Apple Silicon
        .package(url: "https://github.com/waydabber/AppleSiliconDDC.git", branch: "main"),
        // Argument parser for CLI
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "brightness-cli",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AppleSiliconDDC", package: "AppleSiliconDDC")
            ],
            path: "Sources"
        )
    ]
)
