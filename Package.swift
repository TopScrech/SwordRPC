// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "SwordRPC",
    products: [
        .library(
            name: "SwordRPC",
            targets: ["SwordRPC"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/BlueSocket.git", from: "2.0.2")
    ],
    targets: [
        .target(
            name: "SwordRPC",
            dependencies: ["Socket"]
        )
    ]
)
