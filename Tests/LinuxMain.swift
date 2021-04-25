import XCTest

@testable import MustacheTests

var tests = [XCTestCaseEntry]()
tests += MustacheTests.allTests()
XCTMain(tests)
