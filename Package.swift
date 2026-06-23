// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Vintner",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Vintner", targets: ["Vintner"])
    ],
    targets: [
        .target(name: "VintnerCore"),
        .executableTarget(
            name: "Vintner",
            dependencies: ["VintnerCore"]
        ),
        .testTarget(
            name: "VintnerCoreTests",
            dependencies: ["VintnerCore"]
        )
    ]
)
