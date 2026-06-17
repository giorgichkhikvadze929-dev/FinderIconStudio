// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FinderIconStudio",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FinderIconStudio", targets: ["FinderIconStudio"]),
        .library(name: "FinderIconStudioCore", targets: ["FinderIconStudioCore"])
    ],
    targets: [
        .target(
            name: "FinderIconStudioCore",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "FinderIconStudio",
            dependencies: ["FinderIconStudioCore"]
        )
    ]
)
