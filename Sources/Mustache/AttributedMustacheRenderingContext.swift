//
//  AttributedMustacheRenderingContext.swift
//  mustache
//
//  Created by Helge Heß on 26.04.21.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

#if canImport(Foundation)
import class Foundation.NSAttributedString
import class Foundation.NSMutableAttributedString

public typealias AttributedMustacheRenderingFunction =
                   ( NSAttributedString,
                     ( NSAttributedString ) -> NSAttributedString )
                 -> NSAttributedString
public typealias AttributedMustacheSimpleRenderingFunction =
                   ( NSAttributedString ) -> NSAttributedString

public protocol AttributedMustacheRenderingContext {
  
  // MARK: - Content Generation
  
  var  attributedString : NSMutableAttributedString { get }
  func append(_ s: NSAttributedString)

  // MARK: - Cursor
  
  var  cursor : Any? { get }
  func enter(scope ctx: Any?)
  func leave()
  
  // MARK: - Value
  
  func value(forTag tag: String) -> Any?
  
  // MARK: - Lambda Context (same stack, empty String)
  
  func newLambdaContext() -> AttributedMustacheRenderingContext
  
  // MARK: - Partials
  
  func retrievePartial(name n: String) -> AttributedMustacheNode?
}

public extension AttributedMustacheRenderingContext {

  func value(forTag tag: String) -> Any? {
    return KeyValueCoding.value(forKeyPath: tag, inObject: cursor)
  }
  
  func retrievePartial(name n: String) -> MustacheNode? {
    return nil
  }
}

open class AttributedMustacheDefaultRenderingContext
           : AttributedMustacheRenderingContext
{
  
  public let attributedString = NSMutableAttributedString()
  public var stack            = [ Any? ]() // #linux-public
  
  public init(_ root: Any?) {
    if let a = root {
      stack.append(a)
    }
  }
  public init(context: AttributedMustacheDefaultRenderingContext) {
    stack = context.stack
  }
  
  
  // MARK: - Content Generation
  
  public func append(_ s: NSAttributedString) {
    attributedString.append(s)
  }
  
  
  // MARK: - Cursor

  public func enter(scope ctx: Any?) {
    stack.append(ctx)
  }
  public func leave() {
    _ = stack.removeLast()
  }
  
  public var cursor : Any? {
    guard let last = stack.last else { return nil }
    return last
  }
  
  
  // MARK: - Value
  
  open func value(forTag tag: String) -> Any? {
    let check = stack.reversed()
    for c in check {
      if let v = KeyValueCoding.value(forKeyPath: tag, inObject: c) {
        return v
      }
    }
    
    return nil
  }
  
  
  // MARK: - Lambda Context (same stack, empty String)
  
  open func newLambdaContext() -> AttributedMustacheRenderingContext {
    return AttributedMustacheDefaultRenderingContext(context: self)
  }

  
  // MARK: - Partials
  
  open func retrievePartial(name n: String) -> AttributedMustacheNode? {
    return nil
  }
}
#endif // canImport(Foundation)
