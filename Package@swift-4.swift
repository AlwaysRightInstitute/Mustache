// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "Mustache",
  products: [
    .library(name: "Mustache", targets: [ "Mustache" ])
  ],
  targets: [ .target(name: "Mustache") ]
)
