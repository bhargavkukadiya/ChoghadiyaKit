// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChoghadiyaKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "ChoghadiyaKit",
            targets: ["ChoghadiyaKit"]),
        .executable(
            name: "ChoghadiyaDemo",
            targets: ["ChoghadiyaDemo"]),
    ],
    targets: [
        .target(
            name: "ChoghadiyaKit"),
        .executableTarget(
            name: "ChoghadiyaDemo",
            dependencies: ["ChoghadiyaKit"]),
        .testTarget(
            name: "ChoghadiyaKitTests",
            dependencies: ["ChoghadiyaKit"]),
    ]
)
