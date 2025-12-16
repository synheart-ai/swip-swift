// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SWIP",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SWIP",
            targets: ["SWIP"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.0.0"),
        .package(path: "../synheart-wear-swift"),
        .package(path: "../swip-core-swift")
    ],
    targets: [
        .target(
            name: "SWIP",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "SynheartWear", package: "synheart-wear-swift"),
                .product(name: "SwipCore", package: "swip-core-swift")
            ],
            path: "Sources",
            resources: [
                .process("SWIP/Resources")
            ]
        ),
        .testTarget(
            name: "SWIPTests",
            dependencies: ["SWIP"],
            path: "Tests"
        ),
    ]
)
