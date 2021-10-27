//
//  MustacheNode.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016-2021 ZeeZide GmbH. All rights reserved.
//

/// One node of the Mustache template. A template is parsed into a tree of the
/// various nodes.
public enum MustacheNode: Equatable {
  
  case empty
  
  /// Represents the top-level node of a Mustache template, contains the list
  /// of nodes.
  case global([ MustacheNode])
  
  /// Regular CDATA in the template
  case text(String)
  
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
  case section(String, [ MustacheNode ])
  
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
  case invertedSection(String, [ MustacheNode ])
  
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
  case tag(String)
  
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
  case unescapedTag(String)
  
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

public extension MustacheNode {
  
  @inlinable
  var asMustacheString : String {
    var s = String()
    self.append(toString: &s)
    return s
  }
}

public extension MustacheNode {
  
  @inlinable
  func append(toString s : inout String) {
    switch self {
      case .empty: return
      
      case .text(let text):
        s += text
      
      case .global(let nodes):
        nodes.forEach { $0.append(toString: &s) }
      
      case .section(let key, let nodes):
        s += "{{#\(key)}}"
        nodes.forEach { $0.append(toString: &s) }
        s += "{{/\(key)}}"
      
      case .invertedSection(let key, let nodes):
        s += "{{^\(key)}}"
        nodes.forEach { $0.append(toString: &s) }
        s += "{{/\(key)}}"
      
      case .tag(let key):
        s += "{{\(key)}}"
      
      case .unescapedTag(let key):
        s += "{{{\(key)}}}"
      
      case .partial(let key):
        s += "{{> \(key)}}"
    }
  }
}

public extension Sequence where Iterator.Element == MustacheNode {

  @inlinable
  var asMustacheString : String {
    var s = String()
    forEach { $0.append(toString: &s) }
    return s
  }
}


// MARK: - Template Reflection

public extension MustacheNode {
  
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
        set.insert(key)
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

public extension Sequence where Element == MustacheNode {
  
  @inlinable
  var keys : Set<String> {
    var set = Set<String>()
    forEach { $0.addKeys(to: &set) }
    return set
  }
}
public extension Collection where Element == MustacheNode {
  
  @inlinable
  var keys : Set<String> {
    var set = Set<String>()
    forEach { $0.addKeys(to: &set) }
    return set
  }
}
