//
//  AttributedMustacheParser.swift
//  mustache
//
//  Created by Helge Heß on 25.04.21.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

#if canImport(Foundation)
import class Foundation.NSAttributedString

public struct AttributedMustacheParser {
  
  public init() {}
  
  private enum MustacheToken {
    case text                (NSAttributedString)
    case tag                 (NSAttributedString)
    case unescapedTag        (NSAttributedString)
    case sectionStart        (String)
    case invertedSectionStart(String)
    case sectionEnd          (String)
    case partial             (String)
  }
  
  private var start   : UnsafePointer<UTF16.CodeUnit>? = nil
  private var p       : UnsafePointer<UTF16.CodeUnit>? = nil
  private var cStart  : UTF16.CodeUnit = 123 // {
  private var cEnd    : UTF16.CodeUnit = 125 // }
  private let sStart  : UTF16.CodeUnit =  35 // #
  private let isStart : UTF16.CodeUnit =  94 // ^
  private let sEnd    : UTF16.CodeUnit =  47 // /
  private let ueStart : UTF16.CodeUnit =  38 // &
  private let pStart  : UTF16.CodeUnit =  62 // >
  
  public var openCharacter : Character {
    set {
      cStart = String(newValue).utf16.first ?? 123 // {
    }
    get { return Character(UnicodeScalar(UInt32(cStart))!) }
  }
  public var closeCharacter : Character {
    set {
      cEnd = String(newValue).utf16.first ?? 125 // }
    }
    get { return Character(UnicodeScalar(UInt32(cEnd))!) }
  }
  
  
  // MARK: - Client Funcs
  
  private var attributedString : NSAttributedString?
  
  public mutating func parse(attributedString s: NSAttributedString)
                       -> AttributedMustacheNode
  {
    guard !s.string.isEmpty else { return .empty }
    
    self.attributedString = s
    defer { self.attributedString = nil }
    
    let res : AttributedMustacheNode?
            = s.string.utf16.withContiguousStorageIfAvailable
    {
      codeUnits in
      
      start = codeUnits.baseAddress
      p     = start
      
      guard let nodes = parseNodes() else { return .empty }
      return .global(nodes)
    }
    assert(res != nil)
  }
  
  
  // MARK: - Parsing
  
  private mutating func parseNodes(section s: String? = nil)
                        -> [ AttributedMustacheNode ]?
  {
    if p != nil && p!.pointee == 0 { return nil }
    
    var nodes = [ AttributedMustacheNode ]()
    
    while let node = parseNode(sectionEnd: s) {
      switch node {
        case .empty: continue
        default: break
      }
      
      nodes.append(node)
    }
    
    return nodes
  }
  
  private mutating func parseNode(sectionEnd se: String? = nil)
                        -> AttributedMustacheNode?
  {
    guard let token = parseTagOrText() else { return nil }
    
    switch token {
      case .text        (let s): return .text(s)
      case .tag         (let s): return .tag(s)
      case .unescapedTag(let s): return .unescapedTag(s)
      case .partial     (let s): return .partial(s)
      
      case .sectionStart(let s):
        guard let children = parseNodes(section: s) else { return .empty }
        return .section(s, children)
      
      case .invertedSectionStart(let s):
        guard let children = parseNodes(section: s) else { return .empty }
        return .invertedSection(s, children)
      
      case .sectionEnd(let s):
        if !s.isEmpty && s != se {
          print("section tags not balanced: \(s) expected \(se as Optional)")
        }
        return nil
    }
  }
  
  
  // MARK: - Lexing
  
  mutating private func parseTagOrText() -> MustacheToken? {
    guard p != nil && p!.pointee != 0 else { return nil }
    
    if p!.pointee == cStart && la1 == cStart {
      return parseTag()
    }
    else {
      return .text(parseText())
    }
  }
  
  mutating private func parseTag() -> MustacheToken {
    guard p != nil else { return .text("") }
    guard p!.pointee == cStart && la1 == cStart else { return .text("") }
    
    let isUnescaped = la2 == cStart
    
    let start  = p!
    p = p! + (isUnescaped ? 3 : 2) // skip {{
    let marker = p!
    
    while p!.pointee != 0 {
      if p!.pointee == cEnd && la1 == cEnd && (!isUnescaped || la2 == cEnd) {
        // found end
        let len = p! - marker
        
        if isUnescaped {
          p = p! + 3 // skip }}}
          let s = String.fromCString(marker, length: len)!
          return .unescapedTag(s)
        }
        
        p = p! + 2 // skip }}
        
        let typec = marker.pointee
        switch typec {
          case sStart: // #
            let s = String.fromCString(marker + 1, length: len - 1)!
            return .sectionStart(s)
  
          case isStart: // ^
            let s = String.fromCString(marker + 1, length: len - 1)!
            return .invertedSectionStart(s)
  
          case sEnd: // /
            let s = String.fromCString(marker + 1, length: len - 1)!
            return .sectionEnd(s)
            
          case pStart: // >
            var n = marker + 1 // skip >
            while n.pointee == 32 { n += 1 } // skip spaces
            let len = p! - n - 2
            let s = String.fromCString(n, length: len)!
            return .partial(s)

          case ueStart /* & */:
            if (marker + 1).pointee == 32 {
              let s = String.fromCString(marker + 2, length: len - 2)!
              return .unescapedTag(s)
            }
            fallthrough
          
          default:
            let s = String.fromCString(marker, length: len)!
            return .tag(s)
        }
      }
      
      p = p! + 1
    }
    
    return .text(String(cString: start))
  }
  
  mutating private func parseText() -> String {
    assert(p != nil)
    let start = p!
    
    while p!.pointee != 0 {
      if p!.pointee == cStart && la1 == cStart {
        fatalError("NOT IMPLEMENTED")
        //return String.fromCString(start, length: p! - start)!
      }
      
      p = p! + 1
    }
    
    return String(cString: start)
  }
  
  private var la0 : UTF16.CodeUnit { return p != nil ? p!.pointee : 0 }
  private var la1 : UTF16.CodeUnit { return la0 != 0 ? (p! + 1).pointee : 0 }
  private var la2 : UTF16.CodeUnit { return la1 != 0 ? (p! + 2).pointee : 0 }
}

#endif // canImport(Foundation)
