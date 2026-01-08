// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "bEMR",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "CoreDomain", targets: ["CoreDomain"]),
        .library(name: "CoreUseCases", targets: ["CoreUseCases"]),
        .library(name: "FHIRModelsKit", targets: ["FHIRModelsKit"]),
        .library(name: "DataFHIR", targets: ["DataFHIR"]),
        .library(name: "DataLocal", targets: ["DataLocal"]),
        .library(name: "SecurityKit", targets: ["SecurityKit"]),
        .library(name: "SharedPresentation", targets: ["SharedPresentation"]),
        .library(name: "AppSharedUI", targets: ["AppSharedUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/FHIRModels.git", from: "0.7.0")
    ],
    targets: [
        .target(
            name: "CoreDomain",
            path: "Sources/CoreDomain"
        ),
        .target(
            name: "CoreUseCases",
            dependencies: ["CoreDomain"],
            path: "Sources/CoreUseCases"
        ),
        .target(
            name: "FHIRModelsKit",
            dependencies: [
                .product(name: "ModelsR4", package: "FHIRModels")
            ],
            path: "Sources/FHIRModelsKit"
        ),
        .target(
            name: "SecurityKit",
            path: "Sources/SecurityKit"
        ),
        .target(
            name: "DataFHIR",
            dependencies: [
                "CoreDomain",
                "FHIRModelsKit",
                "SecurityKit"
            ],
            path: "Sources/DataFHIR"
        ),
        .target(
            name: "DataLocal",
            dependencies: [
                "CoreDomain",
                "SecurityKit"
            ],
            path: "Sources/DataLocal"
        ),
        .target(
            name: "SharedPresentation",
            dependencies: [
                "CoreDomain",
                "CoreUseCases"
            ],
            path: "Sources/SharedPresentation"
        ),
        .testTarget(
            name: "CoreDomainTests",
            dependencies: ["CoreDomain"],
            path: "Tests/CoreDomainTests"
        ),
        .testTarget(
            name: "CoreUseCasesTests",
            dependencies: ["CoreUseCases", "CoreDomain"],
            path: "Tests/CoreUseCasesTests"
        ),
        .target(
            name: "AppSharedUI",
            dependencies: [
                "SharedPresentation",
                "CoreDomain",
                "CoreUseCases",
                "DataLocal",
                "DataFHIR",
                "SecurityKit"
            ],
            path: "Apps/SharedUI"
        )
    ]
)
