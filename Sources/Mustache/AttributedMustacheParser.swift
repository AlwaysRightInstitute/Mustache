//
//  AttributedMustacheParser.swift
//  mustache
//
//  Created by Helge Heß on 25.04.21.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

#if canImport(Foundation)
import class  Foundation.NSAttributedString
import struct Foundation.NSRange

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
  
  /// Contains the characters in the attributed string using NSString
  /// indexing. It's a hackaround for the different indexing in NSString
  /// and Swift Strings. The characters are only exposed as a Swift String
  /// by NSAttributedString ...
  private var characters       = [ UTF16.CodeUnit ]()
  
  private var cursor           : Int = 0

  public mutating func parse(attributedString s: NSAttributedString)
                       -> AttributedMustacheNode
  {
    guard !s.string.isEmpty else { return .empty }

    attributedString = s
    characters       = Array(s.string.utf16) // yeah, a little lame
    cursor           = 0
    defer {
      attributedString = nil
      cursor = 0
      characters.removeAll()
    }
    
    guard let nodes = parseNodes() else { return .empty }
    return .global(nodes)
  }
  
  
  // MARK: - Parsing
  
  private mutating func parseNodes(section s: String? = nil)
                        -> [ AttributedMustacheNode ]?
  {
    guard !hitEOF else { return nil }
    
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
    guard !hitEOF else { return nil }
    
    return (la0 == cStart && la1 == cStart)
         ? parseTag()
         : .text(parseText())
  }
  
  mutating private func parseTag() -> MustacheToken {
    guard !hitEOF, la0 == cStart && la1 == cStart,
          let attributedString = attributedString else {
      return .text(.init())
    }
    
    let isUnescaped = la2 == cStart
    
    let startCursor = cursor
    cursor += (isUnescaped ? 3 : 2) // skip {{
    var contentStart = cursor
    
    while !hitEOF {
      if la0 == cEnd && la1 == cEnd && (!isUnescaped || la2 == cEnd) {
        // found end
        var contentRange : NSRange { // Intentionally dynamic
          NSRange(location: contentStart, length: cursor - contentStart)
        }
        
        if isUnescaped {
          cursor += 3 // skip "}}}"
          let s = attributedString.attributedSubstring(from: contentRange)
          return .unescapedTag(s)
        }
        
        cursor += 2 // skip "}}"
        
        let typec = la0
        switch typec {
          case sStart: // #
            contentStart += 1
            let s = attributedString.attributedSubstring(from: contentRange)
            return .sectionStart(s.string)
  
          case isStart: // ^
            contentStart += 1
            let s = attributedString.attributedSubstring(from: contentRange)
            return .invertedSectionStart(s.string)
  
          case sEnd: // /
            contentStart += 1
            let s = attributedString.attributedSubstring(from: contentRange)
            return .sectionEnd(s.string)
            
          case pStart: // >
            contentStart += 1 // skip >
            while contentStart < cursor && characters[contentStart] == 32 {
              contentStart += 1 // skip spaces
            }

            let s = attributedString.attributedSubstring(from: contentRange)
            return .partial(s.string)

          case ueStart /* & */:
            let la1: UTF16.CodeUnit = {
              guard characters.count > (contentStart + 1) else { return 0 }
              return characters[contentStart + 1]
            }()
            
            if la1 == 32 {
              let contentRange = NSRange(location : contentStart + 2,
                                         length   : cursor - contentStart - 2)
              let s = attributedString.attributedSubstring(from: contentRange)
              return .unescapedTag(s)
            }
            fallthrough
          
          default: // this is the plain {{tag}}
            let s = attributedString.attributedSubstring(from: contentRange)
            return .tag(s)
        }
      }
      
      cursor += 1
    }
    
    // hit EOF w/o the tag being closed
    let range = NSRange(location : startCursor,
                        length   : attributedString.length - startCursor)
    return .text(attributedString.attributedSubstring(from: range))
  }
  
  mutating private func parseText() -> NSAttributedString {
    guard !hitEOF, let attributedString = attributedString else {
      return NSAttributedString()
    }
    
    let startCursor = cursor
    while !hitEOF && (la0 != cStart && la1 != cStart) { // until "{{"
      cursor += 1
    }
    
    let range = NSRange(location: startCursor, length: cursor - startCursor)
    assert(range.location   >= 0 && range.location   <  attributedString.length)
    assert(range.upperBound >= 0 && range.upperBound <= attributedString.length)
    return attributedString.attributedSubstring(from: range)
  }
  
  
  // MARK: - Buffer Access
  
  private var hitEOF : Bool {
    guard let s = attributedString else { return true }
    return cursor < s.length
  }
  
  private func la(_ p: Int) -> UTF16.CodeUnit? {
    guard cursor + p < characters.count else { return nil }
    assert(cursor + p >= 0)
    return characters[p]
  }
  private var la0 : UTF16.CodeUnit { return la(0) ?? 0 }
  private var la1 : UTF16.CodeUnit { return la(1) ?? 0 }
  private var la2 : UTF16.CodeUnit { return la(2) ?? 0 }
}

#endif // canImport(Foundation)
