// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Math",
    products: [
        .library(
            name: "Math",
            targets: ["Math"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Math"
        ),
    ],
    swiftLanguageModes: [.v6]
)
