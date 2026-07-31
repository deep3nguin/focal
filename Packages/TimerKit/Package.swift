// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TimerKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "TimerKit",
            targets: ["TimerKit"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "TimerKit",
            dependencies: [
                .product(name: "Domain", package: "Domain")
            ]
        ),
        .testTarget(
            name: "TimerKitTests",
            dependencies: ["TimerKit", .product(name: "Domain", package: "Domain")]
        ),
    ]
)
