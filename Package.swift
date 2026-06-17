// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VigramSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "VigramSDK",
            targets: ["VigramSDK"]
        ),
        .library(
            name: "VigramSDK+Rx",
            targets: ["VigramSDK+Rx"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.2.0")
    ],
    targets: [
        .binaryTarget(
            name: "VigramSDK",
            path: "VigramSDK.xcframework"
        ),
        .target(
            name: "VigramSDK+Rx",
            dependencies: [
                "VigramSDK",
                .product(name: "RxSwift", package: "RxSwift")
            ],
            path: "VigramSDK+Rx"
        )
    ],
    swiftLanguageVersions: [.v5]
)
