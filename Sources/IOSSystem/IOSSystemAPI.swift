import Foundation

// The C functions are exposed automatically by the module's umbrella header in SPM mixed targets.
// If not, we might need to rely on the C module being imported.
// Since we are in the same target, Swift should see the C headers in 'include'.

/// A modern, Swift-friendly actor to interact with ios_system.
/// This actor ensures thread-safe access and provides async/await APIs.
@available(iOS 15.0, macOS 12.0, *)
public actor IOSSystem {
    /// Shared singleton instance.
    public static let shared = IOSSystem()

    private init() {}

    /// Executes a shell command asynchronously.
    ///
    /// This method offloads the command execution to a detached task, ensuring that the calling thread
    /// (e.g., the Main Thread) is not blocked, which is crucial for maintaining UI responsiveness in SwiftUI apps.
    ///
    /// - Parameter command: The command string to execute (e.g., "ls -la", "curl https://example.com").
    /// - Returns: The exit code of the command (0 usually indicates success).
    public func run(_ command: String) async -> Int32 {
        return await Task.detached(priority: .userInitiated) {
            // ios_system(const char* inputCmd) -> int
            return command.withCString { cmdPtr in
                // Call the C function directly.
                // In a mixed source target, this should be visible.
                return ios_system(cmdPtr)
            }
        }.value
    }

    /// Checks if a command is executable (either a builtin command or an executable file).
    ///
    /// - Parameter command: The command name to check.
    /// - Returns: `true` if the command is executable, `false` otherwise.
    public nonisolated func isExecutable(_ command: String) -> Bool {
        return command.withCString { cmdPtr in
            return ios_executable(cmdPtr) != 0
        }
    }

    /// Helper to run a command and verify success.
    /// Throws an error if the exit code is not 0.
    public func runCheckingSuccess(_ command: String) async throws {
        let exitCode = await run(command)
        guard exitCode == 0 else {
            throw IOSSystemError.commandFailed(exitCode: exitCode, command: command)
        }
    }
}

/// Errors thrown by IOSSystem.
public enum IOSSystemError: Error, LocalizedError {
    case commandFailed(exitCode: Int32, command: String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let exitCode, let command):
            return "Command '\(command)' failed with exit code \(exitCode)."
        }
    }
}
