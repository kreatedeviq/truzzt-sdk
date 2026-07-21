// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Niv2faSdk",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "Niv2faSdk", targets: ["Niv2faSdk"])
    ],
    targets: [
        .target(
            name: "Niv2faSdk",
            path: "Sources/Niv2faSdk"
        )
    ]
)
