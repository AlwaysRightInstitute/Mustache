//
//  AttributedMustacheRendering.swift
//  mustache
//
//  Created by Helge Heß on 26.04.21.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

#if canImport(Foundation)
import class  Foundation.NSAttributedString
import class  Foundation.NSMutableAttributedString
import struct Mustache.Mustache

#if canImport(AppKit)
  import class AppKit.NSTextAttachment
  import class AppKit.NSTextAttachmentCell
  import class AppKit.NSImage
  typealias UXImage = NSImage
#elseif canImport(UIKit)
  import class UIKit.NSTextAttachment
  import class UIKit.UIImage
  typealias UXImage = UIImage
#endif

public extension AttributedMustacheNode {
  
  func render(object o: Any?, cb: ( NSAttributedString ) -> Void) {
    let ctx = AttributedMustacheDefaultRenderingContext(o)
    render(inContext: ctx, cb: cb)
  }
  
  func render(object o: Any?) -> NSAttributedString {
    let ctx = AttributedMustacheDefaultRenderingContext(o)
    render(inContext: ctx)
    return ctx.attributedString
  }
  
  func render(nodes     nl  : [ AttributedMustacheNode ],
              inContext ctx : AttributedMustacheRenderingContext)
  {
    nl.forEach { node in node.render(inContext: ctx) }
  }
  
  func render(inContext ctx: AttributedMustacheRenderingContext,
              cb: ( NSAttributedString ) -> Void)
  {
    render(inContext: ctx) // TODO: make async for partials
    cb(ctx.attributedString)
  }
  
  func render(inContext ctx: AttributedMustacheRenderingContext) {
    switch self {
      case .empty: return
      
      case .global(let nodes):
        render(nodes: nodes, inContext: ctx)
      
      case .text(let text):
        ctx.append(text)
          
      case .section(let tag, let nodes):
        render(section: tag, nodes: nodes, inContext: ctx)
      
      case .invertedSection(let tag, let nodes):
        let v = ctx.value(forTag: tag)
        guard !Mustache.isMustacheTrue(value: v) else { return }
        render(nodes: nodes, inContext: ctx)
      
      case .tag(let tag), .unescapedTag(let tag): // we don't do escaping here?
        guard let v = ctx.value(forTag: tag.string) else { return }
        
        // Note: No HTML escaping here
        // TBD: support images and NSTextAttachment's directly?
        let attributes = tag.attributes(at: 0, effectiveRange: nil)
        let content : NSAttributedString = {
          switch v {
            #if canImport(AppKit) || canImport(UIKit)
              case let attachment as NSTextAttachment:
                return NSAttributedString(attachment: attachment)
              case let image as UXImage:
                let attachment = NSTextAttachment()
                #if canImport(AppKit)
                  if #available(macOS 10.11, *) {
                    attachment.image = image
                  }
                  let cell = NSTextAttachmentCell(imageCell: image)
                  attachment.attachmentCell = cell
                #else
                  attachment.image = image
                #endif
                return NSAttributedString(attachment: attachment)
            #endif
            case let s as NSAttributedString:
              // TBD: Should we apply our attributes? I don't think so, if the
              //      user provided an Attributed String instead of a regular
              //      String, he probably wants to use the attributes.
              return s
            default:
              let s          = (v as? String) ?? String(describing: v)
              return NSAttributedString(string: s, attributes: attributes)
          }
        }()
        ctx.append(content)

      case .partial(let name):
        guard let partial = ctx.retrievePartial(name: name) else { return }
        partial.render(inContext: ctx)
    }
  }
  
  func render(lambda    cb  : AttributedMustacheRenderingFunction,
              nodes     nl  : [ AttributedMustacheNode ],
              inContext ctx : AttributedMustacheRenderingContext)
  {
    let mustache = nl.asMustacheAttributedString
    let result = cb(mustache) {
      mustacheToRender in
      
      let tree : AttributedMustacheNode
      if mustache == mustacheToRender { // slow, lame
        tree = AttributedMustacheNode.global(nl)
      }
      else { // got a new sub-template to render by the callback
        var parser = AttributedMustacheParser()
        tree = parser.parse(attributedString: mustache)
      }
      
      let lambdaCtx = ctx.newLambdaContext()
      
      tree.render(inContext: lambdaCtx)
      
      return lambdaCtx.attributedString
    }
    ctx.append(result)
  }

  func render(lambda    cb  : MustacheRenderingFunction,
              nodes     nl  : [ AttributedMustacheNode ],
              inContext ctx : AttributedMustacheRenderingContext)
  {
    // TODO: this should preserve the attributes of the lambda context
    let mustache = nl.asMustacheString
    let result = cb(mustache) {
      mustacheToRender in
      
      let tree : AttributedMustacheNode
      if mustache == mustacheToRender { // slow, lame
        tree = AttributedMustacheNode.global(nl)
      }
      else { // got a new sub-template to render by the callback
        var parser = AttributedMustacheParser()
        tree = parser.parse(attributedString:
                                NSAttributedString(string: mustache))
      }
      
      let lambdaCtx = ctx.newLambdaContext()
      
      tree.render(inContext: lambdaCtx)
      
      return lambdaCtx.attributedString.string
    }
    ctx.append(NSAttributedString(string: result))
  }
}

public extension AttributedMustacheNode {
  
  func render(section tag: String, nodes : [ AttributedMustacheNode ],
              inContext ctx: AttributedMustacheRenderingContext)
  {
    let v = ctx.value(forTag: tag)
    guard let vv = v else { return } // nil
    
    // Is it a rendering function?

    if let cb = v as? AttributedMustacheRenderingFunction {
      render(lambda: cb, nodes: nodes, inContext: ctx)
      return
    }
    else if let cb = vv as? AttributedMustacheSimpleRenderingFunction {
      render(lambda: { text, _ in return cb(text) },
             nodes: nodes, inContext: ctx)
    }
    else if let cb = v as? MustacheRenderingFunction {
      render(lambda: cb, nodes: nodes, inContext: ctx)
      return
    }
    else if let cb = vv as? MustacheSimpleRenderingFunction {
      render(lambda: { text, _ in return cb(text) },
             nodes: nodes, inContext: ctx)
    }

    // Is it a plain false?
    
    guard Mustache.isMustacheTrue(value: vv) else { return }
    
    // Reflect on section value
    
    let mirror = Mirror(reflecting: vv)
    let ds     = mirror.displayStyle
    
    if ds == nil { // e.g. Bool in Swift 3
      render(nodes: nodes, inContext: ctx)
      return
    }
    
    switch ds! {
      case .collection:
        for ( _, value ) in mirror.children {
          ctx.enter(scope: value)
          render(nodes: nodes, inContext: ctx)
          ctx.leave()
        }

      case .class, .dictionary: // adjust cursor
        if Mustache.isFoundationBaseType(value: vv) {
          render(nodes: nodes, inContext: ctx)
        }
        else {
          ctx.enter(scope: vv)
          render(nodes: nodes, inContext: ctx)
          ctx.leave()
        }
      
      default:
        // keep cursor for non-collections?
        render(nodes: nodes, inContext: ctx)
    }
  }
}

#endif // canImport(Foundation)
