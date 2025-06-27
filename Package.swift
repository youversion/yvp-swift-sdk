// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YouVersionPlatform",
    platforms: [.macOS(.v15), .iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "YouVersionPlatform",
            targets: ["YouVersionPlatform"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", .upToNextMajor(from: "2.5.5")),
        .package(url: "https://github.com/apple/swift-protobuf.git", .upToNextMajor(from: "1.26.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "YouVersionPlatform",
            dependencies: [
                .product(name: "ZipArchive", package: "ZipArchive"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        ),
        .testTarget(name: "YouVersionPlatformTests", dependencies: ["YouVersionPlatform"]),
    ]
)
