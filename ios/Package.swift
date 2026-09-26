// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TruzztSdk",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "TruzztSdk", targets: ["TruzztSdk"])
    ],
    targets: [
        .target(
            name: "TruzztSdk",
            path: "Sources/TruzztSdk",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
