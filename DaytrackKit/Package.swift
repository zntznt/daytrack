// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DaytrackKit",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "DaytrackCore", targets: ["DaytrackCore"]),
        .library(name: "DaytrackStorage", targets: ["DaytrackStorage"]),
    ],
    targets: [
        .target(name: "DaytrackCore"),
        .target(name: "DaytrackStorage", dependencies: ["DaytrackCore"]),
        .testTarget(name: "DaytrackCoreTests", dependencies: ["DaytrackCore"]),
        .testTarget(name: "DaytrackStorageTests", dependencies: ["DaytrackStorage"]),
    ],
    swiftLanguageModes: [.v6]
)
