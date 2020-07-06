import XCTest

import textTests

var tests = [XCTestCaseEntry]()
tests += textTests.allTests()
XCTMain(tests)
