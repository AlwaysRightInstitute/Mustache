//
//  ReExports.swift
//  mustache
//
//  Created by Helge Heß on 26.04.21.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

@_exported import typealias Mustache.MustacheRenderingFunction
@_exported import typealias Mustache.MustacheSimpleRenderingFunction

#if swift(>=5)

@_exported import struct Mustache.Mustache

#if canImport(Foundation)

@_exported import class Foundation.NSAttributedString

public extension Mustache {
  
  @inlinable
  static func parse(_ template: NSAttributedString) -> AttributedMustacheNode {
    var parser = AttributedMustacheParser()
    return parser.parse(attributedString: template)
  }
}

#endif // canImport(Foundation)
#endif // swift(>=5)
