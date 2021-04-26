//
//  MustacheRendering.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016-2021 ZeeZide GmbH. All rights reserved.
//

public extension MustacheNode {
  
  func render(object o: Any?, cb: ( String ) -> Void) {
    let ctx = MustacheDefaultRenderingContext(o)
    render(inContext: ctx, cb: cb)
  }
  
  func render(object o: Any?) -> String {
    let ctx = MustacheDefaultRenderingContext(o)
    render(inContext: ctx)
    return ctx.string
  }
  
  func render(nodes     nl  : [MustacheNode],
              inContext ctx : MustacheRenderingContext)
  {
    nl.forEach { node in node.render(inContext: ctx) }
  }
  
  func render(inContext ctx: MustacheRenderingContext, cb: ( String ) -> Void) {
    render(inContext: ctx) // TODO: make async for partials
    cb(ctx.string)
  }
  
  func render(inContext ctx: MustacheRenderingContext) {
    switch self {
      case .empty: return
      
      case .global(let nodes):
        render(nodes: nodes, inContext: ctx)
      
      case .text(let text):
        ctx.append(string: text)
          
      case .section(let tag, let nodes):
        render(section: tag, nodes: nodes, inContext: ctx)
      
      case .invertedSection(let tag, let nodes):
        let v = ctx.value(forTag: tag)
        guard !Mustache.isMustacheTrue(value: v) else { return }
        render(nodes: nodes, inContext: ctx)
      
      case .tag(let tag):
        if let v = ctx.value(forTag: tag) {
          if let s = v as? String {
            ctx.append(string: ctx.escape(string: s))
          }
          else {
            ctx.append(string: ctx.escape(string: "\(v)"))
          }
        }
      
      case .unescapedTag(let tag):
        if let v = ctx.value(forTag: tag) {
          if let s = v as? String {
            ctx.append(string: s)
          }
          else {
            ctx.append(string: "\(v)")
          }
        }
      
      case .partial(let name):
        guard let partial = ctx.retrievePartial(name: name) else { return }
        partial.render(inContext: ctx)
    }
  }
  
  func render(lambda    cb  : MustacheRenderingFunction,
              nodes     nl  : [ MustacheNode ],
              inContext ctx : MustacheRenderingContext)
  {
    let mustache = nl.asMustacheString
    let result = cb(mustache) {
      mustacheToRender in
      
      let tree : MustacheNode
      if mustache == mustacheToRender { // slow, lame
        tree = MustacheNode.global(nl)
      }
      else { // got a new sub-template to render by the callback
        var parser = MustacheParser()
        tree = parser.parse(string: mustache)
      }
      
      let lambdaCtx = ctx.newLambdaContext()
      
      tree.render(inContext: lambdaCtx)
      
      return lambdaCtx.string
    }
    ctx.append(string: result)
  }
}

public extension MustacheNode {
  
  func render(section tag: String, nodes : [ MustacheNode ],
              inContext ctx: MustacheRenderingContext)
  {
    let v = ctx.value(forTag: tag)
    guard let vv = v else { return } // nil
    
    // Is it a rendering function?

    if let cb = v as? MustacheRenderingFunction {
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
