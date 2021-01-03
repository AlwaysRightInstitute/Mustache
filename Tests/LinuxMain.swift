import XCTest

@testable import mustacheTests

var tests = [XCTestCaseEntry]()
tests += mustacheTests.allTests()
XCTMain(tests)
