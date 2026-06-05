// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TemperatureCLI",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "temperature-cli",
            dependencies: ["SensorBridge"],
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .target(
            name: "SensorBridge",
            publicHeadersPath: "include"
        )
    ]
)
