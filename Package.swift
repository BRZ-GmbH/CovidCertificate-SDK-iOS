// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CovidCertificateSDK",
    platforms: [
        .iOS(.v12),
        .macOS("10.14"),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CovidCertificateSDK",
            targets: ["CovidCertificateSDK"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "ValidationCore", path: "validationcore-ios"),
        .package(name: "Gzip", url: "https://github.com/1024jp/GzipSwift", .upToNextMajor(from: "5.1.1")),
        .package(name: "SwiftJWT", url: "https://github.com/Kitura/Swift-JWT.git", from: "3.6.1"),
        .package(url: "https://github.com/eu-digital-green-certificates/SwiftCBOR.git", .branch("master")),
        .package(url: "https://github.com/ehn-digital-green-development/base45-swift", .branch("main")),
        .package(name: "jsonlogic", url: "https://github.com/BRZ-GmbH/json-logic-swift.git", .branch("feature/avoid-date-parsing-attempts")),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CovidCertificateSDK",
            dependencies: ["Gzip", "SwiftCBOR", "base45-swift", "SwiftJWT", "jsonlogic", "ValidationCore"],
            exclude: ["ehn/LICENSE.txt"]
        ),
        .testTarget(
            name: "CovidCertificateSDKTests",
            dependencies: ["CovidCertificateSDK", "jsonlogic"]
        ),
    ]
)
