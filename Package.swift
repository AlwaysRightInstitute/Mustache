// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "mustache",
  products: [
    .library(name: "Mustache", targets: [ "Mustache" ]),
  ],
  dependencies: [],
  targets: [
    .target(name:"Mustache"),
    .testTarget(name: "MustacheTests", dependencies: [ "Mustache" ])
  ]
)
