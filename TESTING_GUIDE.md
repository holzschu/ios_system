# iOS System CLI - Comprehensive Testing Guide

**Version**: 1.0  
**Date**: March 2026  
**Purpose**: Validation of optimizations across multiple iOS devices and scenarios

---

## Table of Contents

1. [Test Environment Setup](#test-environment-setup)
2. [Unit Testing](#unit-testing)
3. [Integration Testing](#integration-testing)
4. [Performance Testing](#performance-testing)
5. [Device Testing Matrix](#device-testing-matrix)
6. [Test Automation](#test-automation)
7. [Issue Reporting](#issue-reporting)
8. [Success Criteria](#success-criteria)

---

## Test Environment Setup

### Prerequisites

- **Xcode 14.0+** with iOS SDK 15.0+
- **iOS Simulator** or real iOS devices (iOS 14.0+)
- **Instruments** for performance profiling
- **Command-line tools**: git, xcodebuild, swift
- **Terminal applications**: Blink Shell, OpenTerm (for integration testing)

### Initial Setup

```bash
# Clone repository with submodules
git clone --recurse-submodules https://github.com/PhungKhacVu/ios_system.git
cd ios_system

# Build for testing
xcodebuild \
  -project ios_system.xcodeproj \
  -scheme ios_system \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

# Run unit tests
xcodebuild \
  -project ios_system.xcodeproj \
  -scheme IOSSystemTests \
  -sdk iphonesimulator \
  -configuration Debug \
  test
```

---

## Unit Testing

### Framework Functionality Tests

#### Test 1.1: Basic Command Execution

**Objective**: Verify fundamental command execution works

**Test Cases**:
- [ ] Execute `ls` command in current directory
- [ ] Execute `pwd` command
- [ ] Execute `echo "test"` command
- [ ] Execute `cat /dev/null` command
- [ ] Execute command with environment variables set

**Expected Results**:
- All commands execute successfully
- Output appears in stdout
- Exit codes are correct (0 for success)

**Test Code Example**:
```swift
func testBasicCommandExecution() {
    let cmd = "ls -la"
    let result = ios_system(cmd.cString(using: .utf8))
    XCTAssertEqual(result, 0)
}
```

#### Test 1.2: I/O Redirection

**Objective**: Verify input/output redirection

**Test Cases**:
- [ ] Pipe output from one command to another (`ls | grep`...)
- [ ] Redirect stdout to file (`ls > /tmp/output.txt`)
- [ ] Redirect stderr to file (`ls nonexistent 2> /tmp/errors.txt`)
- [ ] Redirect both stdout and stderr (`ls > /tmp/out.txt 2>&1`)

**Expected Results**:
- Files created with expected content
- Piping works correctly
- Error messages in correct stream

#### Test 1.3: Environment Variables

**Objective**: Verify environment variable handling

**Test Cases**:
- [ ] Set and retrieve custom variable
- [ ] Access HOME variable
- [ ] Modify PATH variable
- [ ] Variable expansion in commands

**Expected Results**:
- Variables set correctly
- Commands access correct values
- Variable expansion works

**Test Code**:
```swift
func testEnvironmentVariables() {
    ios_setenv("TEST_VAR", "test_value", 1)
    let value = ios_getenv("TEST_VAR")
    XCTAssertEqual(String(cString: value), "test_value")
}
```

#### Test 1.4: Working Directory Management

**Objective**: Verify directory navigation

**Test Cases**:
- [ ] Get current directory with `pwd`
- [ ] Change directory with `cd Documents`
- [ ] Navigate to home directory `cd ~`
- [ ] Navigate with `..` (parent directory)
- [ ] Return to previous directory behavior

**Expected Results**:
- `pwd` shows correct directory
- Commands execute in correct directory
- Directory changes persist for session

### Session Management Tests

#### Test 2.1: Single Session Execution

**Objective**: Verify single session operations

**Test Cases**:
- [ ] Create new session
- [ ] Execute multiple commands in sequence
- [ ] Verify session state between commands
- [ ] Close session cleanly

**Expected Results**:
- Session creates and destroys without issues
- State persists correctly

#### Test 2.2: Multiple Session Handling

**Objective**: Verify multi-session support

**Test Cases**:
- [ ] Create 3 parallel sessions
- [ ] Execute different commands in each
- [ ] Switch between sessions
- [ ] Verify isolation between sessions
- [ ] Close all sessions

**Expected Results**:
- Sessions don't interfere with each other
- Switching maintains correct state
- No memory leaks on cleanup

### Error Handling Tests

#### Test 3.1: Command Not Found

**Objective**: Verify error handling for invalid commands

**Test Cases**:
- [ ] Execute non-existent command
- [ ] Check error message
- [ ] Verify exit code (should be non-zero)

**Expected Results**:
- Error message indicates command not found
- Exit code is non-zero (typically 127)
- Session continues after error

#### Test 3.2: File Access Errors

**Objective**: Verify handling of file permission errors

**Test Cases**:
- [ ] Try to read non-existent file
- [ ] Try to write to restricted directory
- [ ] Try to access file outside sandbox

**Expected Results**:
- Appropriate error messages
- Correct exit codes
- No app crash

#### Test 3.3: Signal Handling

**Objective**: Verify signal delivery

**Test Cases**:
- [ ] Send SIGTERM to running command
- [ ] Send SIGINT during command execution
- [ ] Verify command termination
- [ ] Check cleanup

**Expected Results**:
- Signals delivered correctly
- Commands terminate gracefully
- No zombie processes

---

## Integration Testing

### Application Integration Tests

#### Test 4.1: Blink Shell Integration

**Objective**: Test ios_system with Blink Shell app

**Prerequisites**:
- Blink Shell installed on test device
- iOS 15.0+ device/simulator

**Test Cases**:
- [ ] Launch Blink Shell
- [ ] Execute basic commands
- [ ] Test autocomplete
- [ ] Verify output formatting
- [ ] Test interactive commands

**Expected Results**:
- All commands work without crashes
- Output displays correctly
- Performance is acceptable (< 500ms response)

#### Test 4.2: OpenTerm Integration

**Objective**: Test ios_system with OpenTerm app

**Test Cases**:
- [ ] Launch OpenTerm
- [ ] Execute various commands
- [ ] Test file operations
- [ ] Verify theme compatibility

#### Test 4.3: Custom App Integration

**Objective**: Test with custom test app

**Setup**:
1. Create XCTest app that links ios_system framework
2. Include commandDictionary.plist files
3. Call initializeEnvironment() on startup

**Test Cases**:
- [ ] App launches successfully
- [ ] Execute basic command
- [ ] Handle command result
- [ ] Test error cases

---

## Performance Testing

### Startup Performance

#### Test 5.1: App Launch Time

**Objective**: Measure time from launch to first command ready

**Setup**:
```swift
let startTime = Date()
// Initialize ios_system
initializeEnvironment()
let elapsedTime = Date().timeIntervalSince(startTime)
```

**Baseline**: 800-1000ms
**Target**: 300-400ms
**Success**: < 500ms

**Test Cases**:
- [ ] Cold launch (app not in memory)
- [ ] Warm launch (app cached)
- [ ] Launch with small device (4GB RAM)
- [ ] Launch with large device (8GB+ RAM)

#### Test 5.2: First Command Latency

**Objective**: Measure time to execute first command

**Setup**:
```swift
let startTime = Date()
ios_system("ls -la")
let firstCmdTime = Date().timeIntervalSince(startTime)
```

**Baseline**: 200-300ms
**Target**: 50-100ms
**Success**: < 150ms

**Test Cases**:
- [ ] First command: `ls`
- [ ] First command: `cat`
- [ ] First command: `grep`
- [ ] Verify framework load time

#### Test 5.3: Command Execution Throughput

**Objective**: Measure operations per second

**Setup**:
```swift
let commands = Array(repeating: "ls -la", count: 100)
let startTime = Date()
for cmd in commands {
    ios_system(cmd)
}
let elapsed = Date().timeIntervalSince(startTime)
let throughput = 100.0 / elapsed
```

**Target**: > 50 ops/sec (20ms average per command)
**Success**: > 30 ops/sec

**Test Cases**:
- [ ] Simple commands (echo, pwd)
- [ ] File operations (ls, cat)
- [ ] Complex commands (grep patterns)

#### Test 5.4: Memory Usage

**Objective**: Profile memory consumption

**Tools**: Xcode Instruments → Memory

**Test Cases**:
- [ ] Baseline memory at app launch
- [ ] Memory after 10 commands
- [ ] Memory after 100 commands
- [ ] Memory after long session (30 min)
- [ ] Memory cleanup after session close

**Success Criteria**:
- Baseline: < 150KB per session
- Stable: No growth after 100 commands
- Cleanup: Memory released after session close

#### Test 5.5: CPU Usage

**Objective**: Profile CPU consumption

**Tools**: Xcode Instruments → System Trace

**Test Cases**:
- [ ] CPU usage during command execution
- [ ] CPU usage between commands
- [ ] CPU usage for background operations

**Success Criteria**:
- Command execution: < 80% single core
- Idle: < 5% CPU usage
- No sustained high CPU

### Framework Load Performance

#### Test 5.6: Framework Preloading

**Objective**: Verify preload optimization

**Test Cases**:
- [ ] Without preloading: measure first command time
- [ ] With preloading: measure first command time
- [ ] Compare latency improvement

**Expected**: 60-80% latency reduction for preloaded commands

#### Test 5.7: Cache Hit Rates

**Objective**: Measure cache effectiveness

**Test Cases**:
- [ ] Execute same command 100 times
- [ ] Measure cache hits
- [ ] Verify latency improvement

**Success Criteria**:
- Cache hit rate: > 80% after warm-up
- Latency improvement: > 40%

### Stress Testing

#### Test 5.8: High Command Volume

**Objective**: Test sustained high command rate

**Setup**:
```swift
for i in 0..<1000 {
    ios_system("echo test \(i)")
}
```

**Test Cases**:
- [ ] Execute 1000 commands sequentially
- [ ] Monitor memory stability
- [ ] Verify no crashes or hangs
- [ ] Check for resource leaks

**Success Criteria**:
- Completion without errors
- Memory stable (< 10MB total)
- No slowdown with volume

#### Test 5.9: Concurrent Sessions

**Objective**: Test multiple sessions running simultaneously

**Setup**:
```swift
// Create 5 sessions in parallel
for i in 0..<5 {
    ios_switchSession(sessionID_i)
    ios_system("long_running_command")
}
```

**Test Cases**:
- [ ] 5 concurrent sessions
- [ ] 10 concurrent sessions
- [ ] Different command types
- [ ] Verify isolation

**Success Criteria**:
- All sessions complete
- No state corruption
- Performance degradation < 20%

#### Test 5.10: Large File Operations

**Objective**: Test with large files

**Test Cases**:
- [ ] Copy 100MB file: `cp largefile.bin largefile.bak`
- [ ] List large directory (10,000 files): `ls -la`
- [ ] Search in large file: `grep pattern largefile.txt`
- [ ] Archive large directory: `tar -czf archive.tar.gz directory/`

**Success Criteria**:
- Operations complete without crashes
- Memory usage reasonable (< 500MB)
- Performance acceptable (> 10MB/s throughput)

---

## Device Testing Matrix

### Target Devices

| Device | iOS | Processor | RAM | Priority |
|--------|-----|-----------|-----|----------|
| iPhone 15 Pro | 18.x | A17 Pro | 8GB | High |
| iPhone 15 | 18.x | A16 | 6GB | High |
| iPhone 14 | 17.x | A15 | 6GB | Medium |
| iPhone SE 3 | 17.x | A15 | 4GB | High |
| iPhone 13 mini | 17.x | A15 | 4GB | Medium |
| iPad Pro 12.9" | 18.x | M2 | 8GB+ | Medium |
| iPad Air | 17.x | M1 | 8GB | Low |
| iPad (10th gen) | 17.x | A14 | 4GB | Low |

### Device Testing Checklist

For each device, perform these tests:

- [ ] **Basic Functionality**
  - [ ] App launches without crash
  - [ ] Basic commands execute (ls, pwd, echo)
  - [ ] File operations work (mkdir, touch, rm)
  - [ ] Exit to home and relaunch app

- [ ] **Performance**
  - [ ] First command latency < 200ms
  - [ ] Response time acceptable for interactive use
  - [ ] No UI freezing during command execution
  - [ ] Memory usage stable

- [ ] **Device-Specific**
  - [ ] iPad: landscape/portrait orientation changes
  - [ ] iPhone: battery saver mode enabled
  - [ ] iPhone SE: low memory scenario (fill device)
  - [ ] Devices: app backgrounding/resuming

### Low-Memory Device Testing

Special testing for 4GB RAM devices (iPhone SE 3, iPad 10th gen):

```swift
// Test under memory pressure
func testLowMemoryConditions() {
    // Fill available memory
    var buffers: [NSMutableData] = []
    let memoryLimit = 3_000_000_000 // 3GB
    
    while buffers.capacity < memoryLimit {
        buffers.append(NSMutableData(length: 10_000_000)) // 10MB chunks
    }
    
    // Now execute commands under pressure
    XCTAssertEqual(ios_system("ls"), 0)
    XCTAssertEqual(ios_system("pwd"), 0)
}
```

**Success Criteria**:
- Commands still work on 4GB devices
- No crash under memory pressure
- Graceful degradation if needed

---

## Test Automation

### XCTest Suite Structure

```
IOSSystemTests/
├── FunctionalityTests.swift
│   ├── BasicCommandTests
│   ├── IORedirectionTests
│   └── EnvironmentTests
├── PerformanceTests.swift
│   ├── LatencyMeasurementTests
│   ├── ThroughputTests
│   └── MemoryProfilingTests
├── IntegrationTests.swift
│   ├── AppIntegrationTests
│   └── SessionManagementTests
└── StressTests.swift
    ├── HighVolumeTests
    └── ConcurrencyTests
```

### Sample Test Implementation

```swift
import XCTest
@testable import IOSSystem

class IOSSystemPerformanceTests: XCTestCase {
    
    func testFirstCommandLatency() {
        // Warm up by initializing environment
        initializeEnvironment()
        
        // Measure first command execution
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = ios_system("ls -la")
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // Convert to ms
        
        XCTAssertEqual(result, 0, "Command should succeed")
        XCTAssertLessThan(elapsed, 200, "First command latency should be < 200ms")
    }
    
    func testMemoryStability() {
        initializeEnvironment()
        
        let memBefore = getMemoryUsage()
        
        // Execute 100 commands
        for i in 0..<100 {
            let cmd = String(format: "echo test_%d", i)
            ios_system(cmd.cString(using: .utf8))
        }
        
        let memAfter = getMemoryUsage()
        let memGrowth = memAfter - memBefore
        
        XCTAssertLessThan(memGrowth, 5 * 1024 * 1024, "Memory growth should be < 5MB")
    }
    
    func testCachEffectiveness() {
        initializeEnvironment()
        
        // Warm up cache
        ios_system("ls")
        
        // Measure with cache
        let startCached = CFAbsoluteTimeGetCurrent()
        for _ in 0..<10 {
            ios_system("ls")
        }
        let cachedTime = (CFAbsoluteTimeGetCurrent() - startCached) * 1000
        
        let avgCachedTime = cachedTime / 10
        XCTAssertLessThan(avgCachedTime, 50, "Cached command should be < 50ms")
    }
    
    // Helper function
    private func getMemoryUsage() -> Int64 {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size)/4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            task_info(mach_task_self_,
                     task_flavor_t(TASK_BASIC_INFO),
                     $0.pointee,
                     &count)
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}
```

### Automated Test Execution

```bash
# Run all tests
xcodebuild \
  -project ios_system.xcodeproj \
  -scheme IOSSystemTests \
  -configuration Debug \
  -sdk iphonesimulator \
  test

# Run specific test class
xcodebuild \
  -project ios_system.xcodeproj \
  -scheme IOSSystemTests \
  -only-testing IOSSystemTests/IOSSystemPerformanceTests \
  test

# Run with profiling
xcodebuild \
  -project ios_system.xcodeproj \
  -scheme IOSSystemTests \
  -enableCodeCoverage YES \
  test

# Generate coverage report
xcrun xccov view --json \
  build/Intermediates.noindex/XCTest-6d8e5c41/_CodeCoverage_Intermediates/... > coverage.json
```

### Continuous Integration

#### GitHub Actions Workflow

```yaml
name: iOS System Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    strategy:
      matrix:
        xcode: ['14.3', '15.0']
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
      
      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: ${{ matrix.xcode }}
      
      - name: Run Unit Tests
        run: |
          xcodebuild \
            -project ios_system.xcodeproj \
            -scheme IOSSystemTests \
            -sdk iphonesimulator \
            test
      
      - name: Run Performance Tests
        run: |
          xcodebuild \
            -project ios_system.xcodeproj \
            -scheme IOSSystemPerformanceTests \
            -sdk iphonesimulator \
            test
```

---

## Issue Reporting

### Bug Report Template

```markdown
## Issue: [Brief Description]

### Environment
- **Device**: [iPhone X, iPad Air, etc.]
- **iOS Version**: [17.x, 18.x]
- **App**: [Blink Shell, OpenTerm, etc.]
- **ios_system Version**: [Version number]

### Steps to Reproduce
1. [First step]
2. [Second step]
3. ...

### Expected Behavior
[What should happen]

### Actual Behavior
[What actually happens]

### Performance Impact (if applicable)
- Latency: [X ms]
- Memory: [X MB]
- CPU: [X %]

### Logs/Diagnostics
[Output from ios_getDiagnosticInfo()]

### Attachments
- [Screenshots, crash logs, etc.]
```

### Performance Regression Detection

```swift
// Compare with baseline
func testPerformanceRegression() {
    let baseline = 100.0 // ms, from previous build
    
    measure {
        ios_system("ls -la")
    } maxMeasure: baseline
}
```

---

## Success Criteria

### Phase 1 Success Metrics

| Metric | Baseline | Target | Priority |
|--------|----------|--------|----------|
| App startup | 800ms | <500ms | HIGH |
| First command | 200ms | <150ms | HIGH |
| Session memory | 100KB | <80KB | MEDIUM |
| Command throughput | 30 ops/sec | >50 ops/sec | MEDIUM |
| No crashes | - | 0 crashes in 1000 cmds | HIGH |

### Phase 2 Success Metrics

| Metric | Target |
|--------|--------|
| First command | <100ms |
| Cache hit rate | >80% |
| Memory per session | <60KB |
| Concurrent sessions | 10+ stable |

### Phase 3 Success Metrics

| Metric | Target |
|--------|--------|
| Plugin loading | <50ms |
| Hook execution overhead | <5ms |
| Extensibility | Full API stability |

---

## Test Report Template

```markdown
# iOS System Test Report

**Date**: [Date]
**Version**: [Version tested]
**Tester**: [Name]

## Summary
[Executive summary of testing results]

## Test Coverage
- Unit Tests: [X/Y passed]
- Integration Tests: [X/Y passed]
- Performance Tests: [X/Y passed]
- Device Tests: [X/Y passed]

## Results by Category

### Functionality: [PASS/FAIL]
- [Specific result]

### Performance: [PASS/FAIL]
- [Specific result]

### Compatibility: [PASS/FAIL]
- [Device results]

## Issues Found
1. [Issue and severity]
2. [Issue and severity]

## Recommendations
1. [Recommendation]
2. [Recommendation]

## Sign-Off
[Tester signature/approval]
```

---

**Last Updated**: March 2026
**Next Review**: June 2026
