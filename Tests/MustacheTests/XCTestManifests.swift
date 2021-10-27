import XCTest

#if !canImport(ObjectiveC)
public func allTestEntries() -> [ XCTestCaseEntry ] {
  return [
    testCase(MustacheTests.allTests)
  ]
}
#endif
