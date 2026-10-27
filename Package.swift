// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Math",
    products: [
        .library(
            name: "Math",
            targets: ["Math"]
        ),
        .executable(
            name: "t_math",
            targets: ["MathTesting"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Testing.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "Math"
        ),
        .executableTarget(
            name: "MathTesting",
            dependencies: [
                "Math",
                .product(name: "Testing", package: "Testing"),
            ],
            path: "Testing/MathTesting"
        ),
    ],
    swiftLanguageModes: [.v6]
)
