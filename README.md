# Mustache

![Swift4](https://img.shields.io/badge/swift-4-blue.svg)
![Swift5](https://img.shields.io/badge/swift-5-blue.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![tuxOS](https://img.shields.io/badge/os-tuxOS-green.svg?style=flat)
[![Build and Test](https://github.com/AlwaysRightInstitute/Mustache/actions/workflows/swift.yml/badge.svg?branch=main)](https://github.com/AlwaysRightInstitute/Mustache/actions/workflows/swift.yml)

A simple [Mustache](http://mustache.github.io) parser/evaluator for Swift.

[Mustache](http://mustache.github.io) is a very simple templating language.
Implementations are available for pretty much any programming language
(check the [Mustache](http://mustache.github.io) website) - this is one for
Swift.

In the context of Noze.io you don't need to call this manually,
but you can just use the Mustache template support in the
Noze.io [Express](../express) module.
Checkout the [express-simple](../../Samples/express-simple) app as an example
on how to do this.

This Mustache implementation comes with a very simple Key-Value coding
implementation, which is used to extract values from model objects for
rendering.
With that you can render both, generic Dictionary/Array structures as well
as Swift objects with properties.
Since the reflection capabilities of Swift are pretty limited, so is the
KVC implementation.

## Example

Sample Mustache:

    Hello {{name}}
    You have just won {{& value}} dollars!
    {{#in_ca}}
      Well, {{{taxed_value}}} dollars, after taxes.
    {{/in_ca}}
    {{#addresses}}
      Has address in: {{city}}
    {{/addresses}}
    {{^addresses}}
      Has NO addresses
    {{/addresses}}

The template features value access: `{{name}}`,
conditionals: `{{#in_ca}}`,
as well as repetitions: `{{#addresses}}`.

Sample code to parse and evaluate the template:

    let sampleDict  : [ String : Any ] = [
      "name"        : "Chris",
      "value"       : 10000,
      "taxed_value" : Int(10000 - (10000 * 0.4)),
      "in_ca"       : true,
      "addresses"   : [
        [ "city"    : "Cupertino" ]
      ]
    ]
    
    var parser = MustacheParser()
    let tree   = parser.parse(string: template)
    let result = tree.render(object: sampleDict)

You get the idea.

## Swift 5 Dynamic Callable

In Swift 5 you can expose Mustache templates as regular Swift functions.

To declare a Mustache backed function:

```swift
let generateHTMLForWinner = Mustache(
    """
    {% raw %}Hello {{name}}
    You have just won {{& value}} dollars!
    {{#in_ca}}
        Well, {{{taxed_value}}} dollars, after taxes.
    {{/in_ca}}
    {{#addresses}}
        Has address in: {{city}}
    {{/addresses}}
    {{^addresses}}
        Has NO addresses
    {{/addresses}}{% endraw %}
    """
)
```

To call the function:

```swift
let winners = [
    generateHTMLForWinner(
        name: "Chris", value: 10000,
        taxed_value: 6000, in_ca: true,
        addresses: [[ "city": "Cupertino" ]]
    ),
    generateHTMLForWinner(
        name: "Michael", value: 6000,
        taxed_value: 6000, in_ca: false,
        addresses: [[ "city": "Austin" ]]
    )
]
```

Checkout our [blog](http://www.alwaysrightinstitute.com/mustachable/)
for more info on this.


### Who

**mustache** is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.
We don't like people who are wrong.

Ask questions on the [Noze.io Slack](http://slack.noze.io).
