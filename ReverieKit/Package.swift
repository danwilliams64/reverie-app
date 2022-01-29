// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "ReverieKit",
  platforms: [.iOS(.v15)],
  products: [
    .library(name: "ApiClient", targets: ["ApiClient"]),
    .library(name: "ApiClientLive", targets: ["ApiClientLive"]),
    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "AppleMusicClient", targets: ["AppleMusicClient"]),
    .library(name: "HomeFeature", targets: ["HomeFeature"]),
    .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
    .library(name: "SharedModels", targets: ["SharedModels"]),
    .library(name: "ReverieKit", targets: ["ReverieKit"]),
    .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
  ],
  dependencies: [
    .package(url: "https://github.com/adamfootdev/BottomSheet.git", from: "0.2.3"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.33.1"),
    .package(url: "https://github.com/malcommac/SwiftDate", from: "6.3.0"),
  ],
  targets: [
    .target(
      name: "ApiClient",
      dependencies: [
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "ApiClientLive",
      dependencies: [
        "ApiClient",
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "AppFeature",
      dependencies: [
        "ApiClient",
        "ApiClientLive",
        "AppleMusicClient",
        "HomeFeature",
        "OnboardingFeature",
        "SharedModels",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "ReverieKit",
        "SettingsFeature",
      ]
    ),
    .target(
      name: "AppleMusicClient",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "HomeFeature",
      dependencies: [
        "ApiClient",
        "BottomSheet",
        "SettingsFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "OnboardingFeature",
      dependencies: [
        "ApiClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "SharedModels",
      ]
    ),
    .testTarget(
      name: "OnboardingFeatureTests",
      dependencies: [
        "OnboardingFeature",
        "ReverieKit",
      ]
    ),
    .target(
      name: "SharedModels",
      dependencies: [
        .product(name: "SwiftDate", package: "SwiftDate"),
      ]
    ),
    .target(
      name: "ReverieKit",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "SharedModels",
        .product(name: "SwiftDate", package: "SwiftDate"),
      ]
    ),
    .testTarget(
      name: "ReverieKitTests",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "ReverieKit",
      ],
      resources: [
        .process("Resources/"),
      ]
    ),
    .target(
      name: "SettingsFeature",
      dependencies: [
        "AppleMusicClient",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "ReverieKit",
      ]
    ),
  ]
)
