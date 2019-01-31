import XCTest

@testable import mustacheTests

var tests = [XCTestCaseEntry]()
tests += MustacheTests.allTests()
XCTMain(tests)
