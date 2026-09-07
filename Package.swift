// swift-tools-version: 5.9

import PackageDescription

var products: [Product] = []
var targets: [Target] = [
    .target(name: "LangConvertCore"),
    .testTarget(name: "LangConvertCoreTests", dependencies: ["LangConvertCore"])
]

#if os(macOS)
products.append(.executable(name: "LangConvert", targets: ["LangConvert"]))
targets.append(.executableTarget(name: "LangConvert", dependencies: ["LangConvertCore"]))
#endif

let package = Package(
    name: "LangConvert",
    platforms: [.macOS(.v13)],
    products: products,
    targets: targets
)
