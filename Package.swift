// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "prism-calculator",
    defaultLocalization: LanguageTag("en_US"),
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "prism-calculator",
            targets: ["prism-calculator"]),

    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.4"),
        .package(url: "https://github.com/heckj/CameraControlARView.git", from: "0.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "prism-calculator",
            dependencies: [.product(name: "CameraControlARView", package: "CameraControlARView")],
            swiftSettings: [.unsafeFlags([
                "-driver-time-compilation",
                "-Xfrontend",
                "-debug-time-function-bodies",
                "-Xfrontend",
                "-debug-time-expression-type-checking",
                "-Xfrontend",
                "-warn-long-function-bodies=100",
                "-Xfrontend",
                "-warn-long-expression-type-checking=100"
            ])]),
    ]
)
