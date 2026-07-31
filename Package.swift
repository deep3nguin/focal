// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Focal",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Focal", targets: ["FocalAppLib"]),
    ],
    dependencies: [
        .package(path: "./Packages/Domain"),
        .package(path: "./Packages/Data"),
        .package(path: "./Packages/AIKit"),
        .package(path: "./Packages/TimerKit"),
        .package(path: "./Packages/DesignSystem"),
        .package(path: "./Packages/Presentation")
    ],
    targets: [
        .target(
            name: "FocalAppLib",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                .product(name: "Data", package: "Data"),
                .product(name: "AIKit", package: "AIKit"),
                .product(name: "TimerKit", package: "TimerKit"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Presentation", package: "Presentation")
            ],
            path: "App"
        ),
        .testTarget(
            name: "FocalTests",
            dependencies: [
                "FocalAppLib",
                .product(name: "Domain", package: "Domain"),
                .product(name: "Data", package: "Data"),
                .product(name: "AIKit", package: "AIKit"),
                .product(name: "TimerKit", package: "TimerKit"),
                .product(name: "Presentation", package: "Presentation")
            ],
            path: "Tests/FocalTests"
        )
    ]
)
