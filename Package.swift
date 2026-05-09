// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LumiShot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "LumiShotKit", targets: ["LumiShotKit"]),
        .executable(name: "LumiShot", targets: ["LumiShot"])
    ],
    targets: [
        .target(
            name: "LumiShotKit",
            path: "Sources/LumiShot"
        ),
        .executableTarget(
            name: "LumiShot",
            dependencies: ["LumiShotKit"],
            path: "Sources/LumiShotApp",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "LumiShotTests",
            dependencies: ["LumiShotKit"],
            path: "Tests/LumiShotTests"
        )
    ]
)
