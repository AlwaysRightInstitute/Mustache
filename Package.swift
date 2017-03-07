import PackageDescription

let package = Package(
  name: "mustache",
	
	exclude: [
		"mustache.xcodeproj",
		"GNUmakefile",
		"LICENSE",
		"README.md",
		"xcconfig"
	]
)
