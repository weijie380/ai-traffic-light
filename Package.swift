// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TrafficLightApp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TrafficLightApp",
            dependencies: [],
            path: "Sources/TrafficLightApp"
        )
    ]
)
