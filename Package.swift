// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Xion",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Xion",
            targets: ["Xion"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Xion",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI")
            ]),
        .testTarget(
            name: "XionTests",
            dependencies: ["Xion"]),
    ]
) 