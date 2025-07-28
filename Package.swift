// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RouteX",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "RouteX",
            targets: ["RouteX"]
        ),
    ],
    dependencies: [
        // No external dependencies required
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.9.11"),
    ],
    targets: [
        .executableTarget(
            name: "RouteX",
            dependencies: [],
            path: "RouteX",
            sources: [
                "RouteXApp.swift",
                "ContentView.swift", 
                "AddRouteView.swift",
                "RouteManager.swift",
                "RouteModel.swift",
                "CustomTooltip.swift"
            ]
        ),
        .testTarget(
            name: "RouteXTests",
            dependencies: [
                .target(name: "RouteX"),
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            path: "RouteXTests",
            exclude: ["README.md", "routex.code-workspace"],
            sources: ["BasicFunctionalityTests.swift", "ComprehensiveTests.swift"]
        ),
    ]
) 