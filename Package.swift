// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Swift-Deferred",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "Deferred", targets: ["Deferred"]),
  ],
  targets: [
    .target(name: "Deferred"),
    .testTarget(name: "DeferredTests", dependencies: ["Deferred"]),
  ]
)
