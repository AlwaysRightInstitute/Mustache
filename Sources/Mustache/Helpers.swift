//
//  Helpers.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016-2021 ZeeZide GmbH. All rights reserved.
//

#if canImport(Foundation)
import class Foundation.NSNumber
import class Foundation.NSString
import class Foundation.NSValue
#endif

public extension Mustache {

  @inlinable
  static func isFoundationBaseType(value vv: Any) -> Bool {
    #if canImport(Foundation)
      if vv is NSNumber { return true }
      if vv is NSString { return true }
      if vv is NSValue  { return true }
    #endif
    return false
  }

  @inlinable
  static func isMustacheTrue(value v: Any?) -> Bool {
    guard let vv = v else { return false }
    
    if let b = vv as? Bool     { return b }
    if let i = vv as? Int      { return i == 0 ? false : true }
    if let s = vv as? String   { return !s.isEmpty }
    #if canImport(Foundation)
      if let n = vv as? NSNumber { return n.boolValue }
    #endif
    
    let mirror = Mirror(reflecting: vv)
    
    // doesn't want to be displayed?
    guard let ds = mirror.displayStyle else { return false }
    
    // it is a collection, check count
    guard ds == .collection else { return true } // all objects
    return mirror.children.count > 0
  }
}
