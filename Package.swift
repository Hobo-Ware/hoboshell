// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hoboshell",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.1"),
    ],
    targets: [
        .target(name: "HoboshellCore", path: "Sources/HoboshellCore"),
        .executableTarget(
            name: "Hoboshell",
            dependencies: ["HoboshellCore", .product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/Hoboshell"
        ),
        .executableTarget(name: "HoboshellProbe", dependencies: ["HoboshellCore"], path: "Sources/HoboshellProbe"),
        .testTarget(name: "HoboshellCoreTests", dependencies: ["HoboshellCore"], path: "Tests/HoboshellCoreTests"),
    ]
)
