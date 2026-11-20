// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "MathTests",
    products: [
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
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "MathTesting",
            dependencies: [
                .product(name: "Math", package: "Math"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
