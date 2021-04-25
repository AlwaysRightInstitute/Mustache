//
//  Mustacheable.swift
//  mustache
//
//  Created by Helge Heß on 2019-01-31.
//  Copyright © 2019 ZeeZide GmbH. All rights reserved.
//

#if swift(>=5)

/**
 * Expose a Mustache template as a Swift function.
 *
 * To declare a Mustache backed function:
 *
 *     let generateHTMLForWinner = Mustache(
 *           """
 *           Hello {{name}}
 *           You have just won {{& value}} dollars!
 *           {{#in_ca}}
 *             Well, {{{taxed_value}}} dollars, after taxes.
 *           {{/in_ca}}
 *           {{#addresses}}
 *             Has address in: {{city}}
 *           {{/addresses}}
 *           {{^addresses}}
 *             Has NO addresses
 *           {{/addresses}}
 *           """)
 *
 * To call the function:
 *
 *     let winners = [
 *           generateHTMLForWinner(
 *             name: "Chris", value: 10000,
 *             taxed_value: 6000, in_ca: true,
 *             addresses: [[ "city": "Cupertino" ]]
 *           ),
 *           generateHTMLForWinner(
 *             name: "Michael", value: 6000,
 *             taxed_value: 6000, in_ca: false,
 *             addresses: [[ "city": "Austin" ]]
 *           )
 *         ]
 *
 */
@dynamicCallable
public struct Mustache {
  let template : MustacheNode
  
  public init(_ template: String) {
    let parser = MustacheParser()
    self.template = parser.parse(string: template)
  }
  
  public func dynamicallyCall(
                withKeywordArguments args: KeyValuePairs<String, Any>) 
       -> String {
    let dictArgs = Dictionary(uniqueKeysWithValues: 
                                args.map { ( $0.key, $0.value) })
    return template.render(object: dictArgs)
  }
}

#endif // swift(>=5)
