// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LangConvert",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LangConvert", targets: ["LangConvert"])
    ],
    targets: [
        .executableTarget(name: "LangConvert")
    ]
)
