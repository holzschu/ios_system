import XCTest
@testable import text

final class textTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(text().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
