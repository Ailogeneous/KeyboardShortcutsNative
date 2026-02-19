// swift-tools-version:6.1
import PackageDescription

let package = Package(
	name: "KeyboardShortcuts",
	defaultLocalization: "en",
	platforms: [
		.macOS(.v14)
	],
	products: [
		.library(
			name: "KeyboardShortcuts",
			targets: [
				"KeyboardShortcuts"
			]
		)
	],
	targets: [
		.target(
			name: "KeyboardShortcuts",
			dependencies: [],
			path: "Sources/KeyboardShortcuts", // Ensure path is correct
			resources: [
				.process("Resources") // This line is required for local images
			],
			swiftSettings: [
				.swiftLanguageMode(.v5)
			]
		),
		.testTarget(
			name: "KeyboardShortcutsTests",
			dependencies: [
				"KeyboardShortcuts"
			],
			swiftSettings: [
				.swiftLanguageMode(.v5)
			]
		)
	]
)
