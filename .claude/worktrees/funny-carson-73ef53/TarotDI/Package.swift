// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TarotDI",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "TarotDI", targets: ["TarotDI"]),
    ],
    targets: [
        .target(name: "TarotDI", path: "Sources/TarotDI")
    ]
)
