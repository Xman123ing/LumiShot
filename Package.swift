// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LumiShot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "LumiShot", targets: ["LumiShot"]),
        .executable(name: "LumiShotApp", targets: ["LumiShotApp"])
    ],
    targets: [
        .target(
            name: "LumiShot",
            path: "Sources/LumiShot"
        ),
        .executableTarget(
            name: "LumiShotApp",
            dependencies: ["LumiShot"],
            path: "Sources/LumiShotApp"
        ),
        .testTarget(
            name: "LumiShotTests",
            dependencies: ["LumiShot"],
            path: "Tests/LumiShotTests"
        )
    ]
)
