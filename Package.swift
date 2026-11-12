// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hoboshell",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "HoboshellCore", path: "Sources/HoboshellCore"),
        .executableTarget(name: "Hoboshell", dependencies: ["HoboshellCore"], path: "Sources/Hoboshell"),
        .executableTarget(name: "HoboshellProbe", dependencies: ["HoboshellCore"], path: "Sources/HoboshellProbe"),
        .testTarget(name: "HoboshellCoreTests", dependencies: ["HoboshellCore"], path: "Tests/HoboshellCoreTests"),
    ]
)
