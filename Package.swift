// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "VigramSDK",
    platforms: [.macOS(.v10_15), .iOS(.v14)],
    products: [
        .library(
            name: "VigramSDK",
            targets: ["VigramSDK"]),
        .library(
            name: "VigramSDK+Rx",
            targets: ["VigramSDK+Rx"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.2.0")
    ],
    targets: [
        .target(
            name: "VigramSDK+Rx",
            dependencies: ["VigramSDK", "RxSwift"],
            path: "VigramSDK+Rx"),
        .binaryTarget(
            name: "VigramSDK",
            path: "VigramSDK.xcframework"),
    ]
)
