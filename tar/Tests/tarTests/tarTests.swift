import XCTest
@testable import tar

final class tarTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(tar().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
