// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "mustache",
  products: [
    .library(name: "mustache", targets: ["mustache"]),
  ],
  dependencies: [],
  targets: [ .target(name:"mustache") ]
)
