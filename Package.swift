// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "Mustache",
  products: [
    .library(name: "Mustache", targets: [ "Mustache" ]),
    .library(name: "AttributedMustache", targets: [ "AttributedMustache" ])
  ],
  dependencies: [],
  targets: [
    .target(name: "Mustache"),
    .target(name: "AttributedMustache", dependencies: [ "Mustache" ]),
    .testTarget(name: "MustacheTests",
                dependencies: [ "Mustache", "AttributedMustache" ])
  ]
)
