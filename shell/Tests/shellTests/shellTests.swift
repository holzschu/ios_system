import XCTest
@testable import shell

final class shellTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(shell().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
