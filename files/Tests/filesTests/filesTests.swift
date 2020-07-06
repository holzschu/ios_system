import XCTest
@testable import files

final class filesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(files().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
