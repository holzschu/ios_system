import XCTest

import filesTests

var tests = [XCTestCaseEntry]()
tests += filesTests.allTests()
XCTMain(tests)
