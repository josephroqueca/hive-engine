// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "HiveEngine",
	platforms: [
		.macOS(.v10_15),
		.iOS("13.4"),
	],
	products: [
		.library(name: "HiveEngine", targets: ["HiveEngine"]),
	],
	dependencies: [
		.package(url: "https://github.com/sharplet/Regex.git", from: "2.1.0"),
	],
	targets: [
		.target(name: "HiveEngine", dependencies: [.product(name: "Regex", package: "Regex")]),
		.testTarget(name: "HiveEngineTests", dependencies: [.target(name: "HiveEngine")]),
	]
)
