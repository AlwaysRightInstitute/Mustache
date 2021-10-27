//
//  MustacheParser3.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016-2021 ZeeZide GmbH. All rights reserved.
//

public struct MustacheParser {
  
  public init() {}
  
  private enum MustacheToken {
    case text                (String)
    case tag                 (String)
    case unescapedTag        (String)
    case sectionStart        (String)
    case invertedSectionStart(String)
    case sectionEnd          (String)
    case partial             (String)
  }
  
  private var start   : UnsafePointer<CChar>? = nil
  private var p       : UnsafePointer<CChar>? = nil
  private var cStart  : CChar = 123 // {
  private var cEnd    : CChar = 125 // }
  private let sStart  : CChar =  35 // #
  private let isStart : CChar =  94 // ^
  private let sEnd    : CChar =  47 // /
  private let ueStart : CChar =  38 // &
  private let pStart  : CChar =  62 // >
  
  public var openCharacter : Character {
    set {
      let s = String(newValue).unicodeScalars
      cStart = CChar(s[s.startIndex].value)
    }
    get { return Character(UnicodeScalar(UInt32(cStart))!) }
  }
  public var closeCharacter : Character {
    set {
      let s = String(newValue).unicodeScalars
      cEnd = CChar(s[s.startIndex].value)
    }
    get { return Character(UnicodeScalar(UInt32(cEnd))!) }
  }
  
  
  // MARK: - Client Funcs
  
  @inlinable
  public mutating func parse(string s: String) -> MustacheNode {
    return s.withCString { cs in
      parse(cstr: cs)
    }
  }
  
  public mutating func parse(cstr cs: UnsafePointer<CChar>) -> MustacheNode {
    if cs.pointee == 0 { return .empty }
    
    start = cs
    p     = start
    
    guard let nodes = parseNodes() else { return .empty }
    return .global(nodes)
  }
  
  
  // MARK: - Parsing
  
  private mutating func parseNodes(section s: String? = nil)
                        -> [ MustacheNode ]?
  {
    if p != nil && p!.pointee == 0 { return nil }
    
    var nodes = [ MustacheNode ]()
    
    while let node = parseNode(sectionEnd: s) {
      switch node {
        case .empty: continue
        default: break
      }
      
      nodes.append(node)
    }
    
    return nodes
  }
  
  private mutating func parseNode(sectionEnd se: String? = nil) -> MustacheNode?
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
        return String.fromCString(start, length: p! - start)!
      }
      
      p = p! + 1
    }
    
    return String(cString: start)
  }
  
  private var la0 : CChar { return p != nil ? p!.pointee : 0 }
  private var la1 : CChar { return la0 != 0 ? (p! + 1).pointee : 0 }
  private var la2 : CChar { return la1 != 0 ? (p! + 2).pointee : 0 }
}

#if os(Linux)
  import func Glibc.memcpy
#else
  import func Darwin.memcpy
#endif

fileprivate extension String {
  
  static func fromCString(_ cs: UnsafePointer<CChar>, length olength: Int?)
              -> String?
  {
    guard let length = olength else { // no length given, use \0 std imp
      return String(validatingUTF8: cs)
    }
    
    let buflen = length + 1
    let buf    = UnsafeMutablePointer<CChar>.allocate(capacity: buflen)
    memcpy(buf, cs, length)
    buf[length] = 0 // zero terminate

    let s = String(validatingUTF8: buf)
    #if swift(>=4.1)
      buf.deallocate()
    #else
      buf.deallocate(capacity: buflen)
    #endif

    return s
  }
}
