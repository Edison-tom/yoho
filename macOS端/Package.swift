// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Yoho",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Yoho", targets: ["Yoho"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Yoho",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/Yoho",
            resources: [
                .process("Assets.xcassets"),
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "YohoTests",
            dependencies: ["Yoho"],
            path: "Tests/YohoTests"
        ),
    ]
)
