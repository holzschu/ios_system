import XCTest
@testable import ios_system

final class IOSSystemTests: XCTestCase {
    func testExecutableCheck() {
        let system = IOSSystem.shared
        // "ls" should be executable (it's built-in or in path)
        XCTAssertTrue(system.isExecutable("ls"))
        XCTAssertFalse(system.isExecutable("nonexistent_command"))
    }

    func testAsyncRun() async {
        let system = IOSSystem.shared
        // Running "ls" should succeed.
        // Note: Output capture is not implemented in this basic wrapper test,
        // but we verify exit code.
        let exitCode = await system.run("ls")
        XCTAssertEqual(exitCode, 0)
    }

    func testRunCheckingSuccess() async {
        let system = IOSSystem.shared
        do {
            try await system.runCheckingSuccess("ls")
        } catch {
            XCTFail("ls command failed: \(error)")
        }

        do {
            try await system.runCheckingSuccess("command_that_fails_hopefully")
            XCTFail("Should have thrown error")
        } catch {
            // Success if it throws
        }
    }
}
