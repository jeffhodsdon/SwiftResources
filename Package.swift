// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftResources",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "sr", targets: ["SwiftResources"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftResources",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftResourcesTests",
            dependencies: ["SwiftResources"],
            path: "Tests"
        ),
    ]
)
