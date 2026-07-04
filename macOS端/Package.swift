// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Yoho",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Yoho", targets: ["Yoho"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Yoho",
            dependencies: [],
            path: "Sources/Yoho"
        )
    ]
)
