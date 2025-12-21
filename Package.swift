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
    targets: [
        .executableTarget(
            name: "SwiftResources",
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftResourcesTests",
            dependencies: ["SwiftResources"],
            path: "Tests"
        ),
    ]
)
