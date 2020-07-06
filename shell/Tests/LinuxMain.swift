import XCTest

import shellTests

var tests = [XCTestCaseEntry]()
tests += shellTests.allTests()
XCTMain(tests)
