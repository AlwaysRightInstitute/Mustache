//
//  AttributedMustacheTests.swift
//  MustacheTests
//
//  Created by Helge Heß on 26.04.21.
//  Copyright © 2021 ZeeZide GmbH. All rights reserved.
//

#if canImport(Foundation)

import XCTest
@testable import Mustache

class AttributedMustacheTests: XCTestCase {
  
  let fixTaxTemplate : NSAttributedString = {
    let ms = NSMutableAttributedString(string:
      """
      Hello {{name}}
      You have just won {{& value}} dollars!
      {{#in_ca}}
      Well, {{{taxed_value}}} dollars, after taxes.{{/in_ca}}
      {{#addresses}}  Has address in: {{city}}{{/addresses}}
      {{^addresses}}Has NO addresses{{/addresses}}
      """
    )
    ms.setAttributes([.foregroundColor: "red"], range: NSMakeRange(6, 0))
    return ms
  }()
  let fixTaxTemplate2 : NSAttributedString = {
    // same but no {{& x} inverted sections
    let ms = NSMutableAttributedString(string:
      """
      Hello {{name}}
      You have just won {{{value}}} dollars!
      {{#in_ca}}
      Well, {{{taxed_value}}} dollars, after taxes.{{/in_ca}}
      {{#addresses}}  Has address in: {{city}}{{/addresses}}
      {{^addresses}}Has NO addresses{{/addresses}}
      """
    )
    ms.setAttributes([.foregroundColor: "red"], range: NSMakeRange(6, 0))
    return ms
  }()
  
  let baseTemplate = NSAttributedString(string:
    "<h2>Names</h2>\n" +
    "{{#names}}" +
    "  {{>     user}}\n" +
    "{{/names}}"
  )
  let userTemplate = NSAttributedString(string: "<strong>{{lastname}}</strong>")
  
  let fixDictChris : [ String : Any ] = [
    "name"        : "Ch<r>is",
    "value"       : 10000,
    "taxed_value" : Int(10000 - (10000 * 0.4)),
    "in_ca"       : true,
    "addresses"   : [
      [ "city"    : "Cupertino" ]
    ]
  ]
  
  let fixUsers = [
    [ "lastname": "Duck",  "firstname": "Donald"   ],
    [ "lastname": "Duck",  "firstname": "Dagobert" ],
    [ "lastname": "Mouse", "firstname": "Mickey"   ]
  ]
  let fixUsersClass = [
    PersonClass("Donald",   "Duck"),
    PersonClass("Dagobert", "Duck"),
    PersonClass("Mickey",   "Mouse")
  ]
  let fixUsersStruct = [
    PersonStruct("Donald",   "Duck"),
    PersonStruct("Dagobert", "Duck"),
    PersonStruct("Mickey",   "Mouse")
  ]
  
  let fixChrisResult =
    "Hello Ch&lt;r&gt;is\n" +
    "You have just won 10000 dollars!\n" +
    "\n" +
    "Well, 6000 dollars, after taxes." +
    "\n" +
    "" +
    "  Has address in: Cupertino" +
    "" +
  ""
  
  let fixFullNameKVCTemplate1 = NSAttributedString(string:
        "{{#persons}}{{firstname}} {{lastname}}\n{{/persons}}")
  let fixFullNameKVCResults1 = "Donald Duck\nDagobert Duck\nMickey Mouse\n"
  
  let fixLambdaTemplate1 = NSAttributedString(string:
    "{{#wrapped}}{{name}} is awesome.{{/wrapped}}")
  
  let fixLambda1 : [ String : Any ] = [
    "name"    : "Willy",
    "wrapped" : { ( text: String, render: ( String ) -> String ) -> String in
      return "<b>" + render(text) + "</b>"
    }
  ]
  let fixSimpleLambda1 : [ String : Any ] = [
    "name"    : "Willy",
    "wrapped" : { ( text: String ) -> String in return "<b>" + text + "</b>" }
  ]
  
  let fixLambda1Result       = "<b>Willy is awesome.</b>"
  let fixSimpleLambda1Result = "<b>{{name}} is awesome.</b>"
  let fixPartialResult1 =
    "<h2>Names</h2>\n" +
    "  <strong>Duck</strong>\n" +
    "  <strong>Duck</strong>\n" +
    "  <strong>Mouse</strong>\n"
  
  // MARK: - Tests

  func testDictKVC() throws {
    let v = KeyValueCoding.value(forKey: "name", inObject: fixDictChris)
    XCTAssertNotNil(v)
    if v != nil {
      XCTAssertTrue(v! is String)
      XCTAssertEqual(v as? String, "Ch<r>is")
    }
  }
  
  func testDictNumberKVC() throws {
    let v = KeyValueCoding.value(forKey: "value", inObject: fixDictChris)
    XCTAssertNotNil(v)
    if v != nil {
      XCTAssertTrue(v! is Int)
      XCTAssertEqual(v as? Int, 10000)
    }
  }
  
  func testSimpleMustacheDict() throws {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: fixTaxTemplate)
    let result = tree.render(object: fixDictChris)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixChrisResult)
  }
  
  func testTreeRendering() throws {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: fixTaxTemplate2)
    let result = tree.asMustacheString
    
    XCTAssertEqual(result, fixTaxTemplate2)
  }
  
  func testClassKVCRendering() throws  {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: fixFullNameKVCTemplate1)
    let result = tree.render(object: ["persons": fixUsersClass])
    
    XCTAssertEqual(result, fixFullNameKVCResults1)
  }
  
  func testStructKVCRendering() throws {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: fixFullNameKVCTemplate1)
    let result = tree.render(object: ["persons": fixUsersClass])
    
    XCTAssertEqual(result, fixFullNameKVCResults1)
  }
  
  func testLambda() throws {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: fixLambdaTemplate1)
    let result = tree.render(object: fixLambda1)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixLambda1Result)
  }
  
  func testSimpleLambda() throws {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: fixLambdaTemplate1)
    let result = tree.render(object: fixSimpleLambda1)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixSimpleLambda1Result)
  }
  
  func testPartialParsing() throws {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: baseTemplate)
    
    XCTAssertNotNil(tree)
    // print("tree: \(tree)")
    // print("tree: \(tree.asMustacheString)")
  }
  
  
  // MARK: - Test Partials
  
  class TestCtx : AttributedMustacheDefaultRenderingContext {
    
    var nameToTemplate = [ String : NSAttributedString ]()
    
    override func retrievePartial(name n: String) -> AttributedMustacheNode? {
      guard let template = nameToTemplate[n] else { return nil }
      
      var parser = AttributedMustacheParser()
      let tree   = parser.parse(attributedString: template)
      return tree
    }
    
  }
  
  func testPartial() throws {
    var parser = AttributedMustacheParser()
    let tree   = parser.parse(attributedString: baseTemplate)

    let ctx = TestCtx(["names": fixUsers])
    ctx.nameToTemplate["base"] = baseTemplate
    ctx.nameToTemplate["user"] = userTemplate
    tree.render(inContext: ctx)
    let result = ctx.string
    
    //print("result: \(result)")
    XCTAssertNotNil(result)
    XCTAssertEqual(result, fixPartialResult1)
  }
  
  #if false // TODO: Add support for attributed strings
  // MARK: - Swift 5 Features
  func testDynamicallyCallableMustache() {
    #if swift(>=5)
    let fixTax = Mustache(fixTaxTemplate)
    let result = fixTax(name: "Ch<r>is",
      value       : 10000,
      taxed_value : Int(10000 - (10000 * 0.4)),
      in_ca       : true,
      addresses   : [ [ "city"    : "Cupertino" ] ]
    )
    print("R:", result)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixChrisResult)
    #endif
  }
  #else
  func testDynamicallyCallableMustache() {
    XCTAssert(false, "not implemented")
  }
  #endif
  
  
  static var allTests = [
    ( "testSimpleMustacheDict", testSimpleMustacheDict ),
    ( "testDictKVC"           , testDictKVC            ),
    ( "testDictNumberKVC"     , testDictNumberKVC      ),
    ( "testTreeRendering"     , testTreeRendering      ),
    ( "testClassKVCRendering" , testClassKVCRendering  ),
    ( "testStructKVCRendering", testStructKVCRendering ),
    ( "testLambda"            , testLambda             ),
    ( "testSimpleLambda"      , testSimpleLambda       ),
    ( "testPartialParsing"    , testPartialParsing     ),
    ( "testPartial"           , testPartial            )
  ]
}

#endif // canImport(Foundation)
