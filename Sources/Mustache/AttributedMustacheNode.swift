//
//  AttributedMustacheNode.swift
//  mustache
//
//  Created by Helge Heß on 25.04.21.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

#if canImport(Foundation)
import class Foundation.NSAttributedString
import class Foundation.NSMutableAttributedString

/// One node of the Mustache template. A template is parsed into a tree of the
/// various nodes.
public enum AttributedMustacheNode: Equatable {
  
  case empty
  
  /// Represents the top-level node of a Mustache template, contains the list
  /// of nodes.
  case global([ AttributedMustacheNode])
  
  /// Regular CDATA in the template
  case text(NSAttributedString)
  
  /// A section, can be either a repetition (if the value evaluates to a
  /// Sequence) or a conditional (if the value resolves to true/false).
  /// If the value is false or an empty list, the contained nodes won't be
  /// rendered.
  /// If the value is a Sequence, the contained items will be rendered n-times,
  /// once for each member. The rendering context is changed to the item before
  /// rendering.
  /// If the value is not a Sequence, but considered 'true', the contained nodes
  /// will get rendered once.
  ///
  /// A Mustache section is introduced with a "{{#" tag and ends with a "{{/"
  /// tag.
  /// Example:
  ///
  ///     {{#addresses}}
  ///       Has address in: {{city}}
  ///     {{/addresses}}
  ///
  case section(String, [ AttributedMustacheNode ])
  
  /// An inverted section either displays its contents or not, it never repeats.
  ///
  /// If the value is 'false' or an empty list, the contained nodes will get
  /// rendered.
  /// If it is 'true' or a non-empty list, it won't get rendered.
  ///
  /// An inverted section is introduced with a "{{^" tag and ends with a "{{/"
  /// tag.
  /// Example:
  ///
  ///     {{^addresses}}
  ///       The person has no addresses assigned.
  ///     {{/addresses}}
  ///
  case invertedSection(String, [ AttributedMustacheNode ])
  
  /// A Mustache Variable. Will try to lookup the given string as a name in the
  /// current context. If the current context doesn't have the name, the lookup
  /// is supposed to continue at the parent contexts.
  ///
  /// The resulting value will be HTML escaped.
  ///
  /// Example:
  ///
  ///     {{city}}
  ///
  case tag(NSAttributedString)
  
  /// This is the same like Tag, but the value won't be HTML escaped.
  ///
  /// Use triple braces for unescaped variables:
  ///
  ///     {{{htmlToEmbed}}}
  ///
  /// Or use an ampersand, like so:
  ///
  ///     {{^ htmlToEmbed}}
  ///
  case unescapedTag(NSAttributedString)
  
  /// A partial. How this is looked up depends on the rendering context
  /// implementation.
  ///
  /// Partials are included via "{{>", like so:
  ///
  ///     {{#names}}
  ///       {{> user}}
  ///     {{/names}}
  ///
  case partial(String)
}

// MARK: - Convert parsed nodes back to a String template

public extension AttributedMustacheNode {
  
  @inlinable
  var asMustacheString : String {
    var s = String()
    self.append(toString: &s)
    return s
  }
  @inlinable
  var asMustacheAttributedString : NSAttributedString {
    let s = NSMutableAttributedString()
    self.append(toAttributedString: s)
    return NSAttributedString(attributedString: s)
  }
}

public extension AttributedMustacheNode {
  
  @inlinable
  func append(toString s : inout String) {
    switch self {
      case .empty: return
      
      case .text(let text):
        s += text.string
      
      case .global(let nodes):
        nodes.forEach { $0.append(toString: &s) }
      
      case .section(let key, let nodes):
        s += "{{#" + key + "}}"
        nodes.forEach { $0.append(toString: &s) }
        s += "{{/" + key + "}}"
      
      case .invertedSection(let key, let nodes):
        s += "{{^" + key + "}}"
        nodes.forEach { $0.append(toString: &s) }
        s += "{{/" + key + "}}"

      case .tag(let attributedKey):
        s += "{{" + attributedKey.string + "}}"
      
      case .unescapedTag(let attributedKey):
        s += "{{{" + attributedKey.string + "}}}"
      
      case .partial(let key):
        s += "{{> " + key + "}}"
    }
  }

  @inlinable
  func append(toAttributedString s: NSMutableAttributedString) {
    switch self {
      case .empty: return
      
      case .text(let text):
        s.append(text)
      
      case .global(let nodes):
        nodes.forEach { $0.append(toAttributedString: s) }
      
      case .section(let key, let nodes):
        s.append(NSAttributedString(string: "{{#\(key)}}"))
        nodes.forEach { $0.append(toAttributedString: s) }
        s.append(NSAttributedString(string: "{{/\(key)}}"))
      
      case .invertedSection(let key, let nodes):
        s.append(NSAttributedString(string: "{{^\(key)}}"))
        nodes.forEach { $0.append(toAttributedString: s) }
        s.append(NSAttributedString(string: "{{/\(key)}}"))
      
      case .tag(let key):
        s.append(NSAttributedString(string: "{{"))
        s.append(key)
        s.append(NSAttributedString(string: "}}"))

      case .unescapedTag(let key):
        s.append(NSAttributedString(string: "{{{"))
        s.append(key)
        s.append(NSAttributedString(string: "}}}"))
      
      case .partial(let key):
        s.append(NSAttributedString(string: "{{> \(key)}}"))
    }
  }
}

public extension Sequence where Iterator.Element == AttributedMustacheNode {

  @inlinable
  var asMustacheString : String {
    var s = String()
    forEach { $0.append(toString: &s) }
    return s
  }
  @inlinable
  var asMustacheAttributedString : NSAttributedString {
    let s = NSMutableAttributedString()
    forEach { $0.append(toAttributedString: s) }
    return NSAttributedString(attributedString: s)
  }
}


// MARK: - Template Reflection

public extension AttributedMustacheNode {
  
  @inlinable
  var hasKeys: Bool {
    switch self {
      case .empty, .text: return false
      case .section, .invertedSection, .tag, .unescapedTag: return true
      case .global(let nodes):
        return nodes.firstIndex(where: { $0.hasKeys }) != nil
      case .partial: return true
    }
  }
  
  @usableFromInline
  internal func addKeys(to set: inout Set<String>) {
    switch self {
      case .empty, .text: return
      case .global(let nodes): nodes.forEach { $0.addKeys(to: &set) }
      case .section(let key, let nodes), .invertedSection(let key, let nodes):
        set.insert(key)
        nodes.forEach { $0.addKeys(to: &set) }
      case .tag(let key), .unescapedTag(let key):
        set.insert(key.string)
      case .partial:
        return
    }
  }
  
  @inlinable
  var keys : Set<String> {
    var set = Set<String>()
    addKeys(to: &set)
    return set
  }
}

public extension Sequence where Element == AttributedMustacheNode {
  
  @inlinable
  var keys : Set<String> {
    var set = Set<String>()
    forEach { $0.addKeys(to: &set) }
    return set
  }
}
public extension Collection where Element == AttributedMustacheNode {
  
  @inlinable
  var keys : Set<String> {
    var set = Set<String>()
    forEach { $0.addKeys(to: &set) }
    return set
  }
}
#endif // canImport(Foundation)
