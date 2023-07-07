// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Auth0Kit",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "Auth0Kit",
            targets: ["Auth0Kit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
    ],
    targets: [
        .target(
            name: "Auth0Kit",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "JWT", package: "jwt"),
            ]
        ),
        .testTarget(
            name: "Auth0KitTests",
            dependencies: ["Auth0Kit"]),
    ]
)
