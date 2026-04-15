// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FilmPostCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "FilmPostCore",
            targets: ["FilmPostCore"]
        ),
    ],
    targets: [
        .target(
            name: "FilmPostCore"
        ),
        .testTarget(
            name: "FilmPostCoreTests",
            dependencies: ["FilmPostCore"]
        ),
    ]
)
