import XCTest
@testable import ios_system

final class ios_systemTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ios_system().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
