# iOS System CLI Optimization - Developer Quick Reference

**Last Updated**: March 2026  
**Quick Links**: [Report](./OPTIMIZATION_REPORT.md) | [Roadmap](./IMPLEMENTATION_ROADMAP.md) | [Testing](./TESTING_GUIDE.md) | [Summary](./OPTIMIZATION_SUMMARY.md)

---

## At a Glance

| Aspect | Current | Target | Improvement |
|--------|---------|--------|-------------|
| **First command latency** | 200-300ms | <100ms | **60-70%** |
| **Session memory** | 100-150KB | <70KB | **40-50%** |
| **Context switches** | 5-10ms | <2ms | **75-80%** |
| **Path resolution** | 5-8ms | <1ms | **80-85%** |
| **Concurrent sessions** | Limited | 10+ | **8x improvement** |

---

## Optimization Priorities

### Phase 1 (Weeks 1-3) - 40% Improvement
```
1. Command preloading          [HIGH IMPACT]
   └─ Reduce first-cmd latency 60-80%
   
2. Context type enum           [QUICK WIN]
   └─ Improve signal handling 30%
   
3. Session optimization        [HIGH VALUE]
   └─ Reduce context switches 50-70%
```

### Phase 2 (Weeks 4-6) - +15% Improvement
```
1. Path bookmark caching       [HIGH IMPACT]
   └─ 70% path resolution speedup
   
2. Output buffering            [MEMORY]
   └─ 40% improvement for high-output commands
   
3. Command queue refactoring   [STABILITY]
   └─ 30% memory reduction
   
4. Fine-grained locking        [THREADING]
   └─ Enable 10+ concurrent sessions
```

### Phase 3 (Weeks 7-10) - Extensibility
```
1. Plugin architecture         [ECOSYSTEM]
2. Hook system                 [CUSTOMIZATION]
3. Configuration system        [USER CONTROL]
4. Lazy command loading        [STARTUP]
```

### Phase 4 (Weeks 11-13) - Quality
```
1. Comprehensive testing       [CONFIDENCE]
2. Device compatibility        [COMPATIBILITY]
3. Performance validation      [VERIFICATION]
4. Documentation               [SUPPORT]
```

---

## Core APIs to Implement

### Performance Monitoring
```c
// Enable/disable performance collection
ios_enablePerformanceMonitoring(1);

// Get metrics for current session
ios_performance_metrics_t metrics = ios_getPerformanceMetrics(NULL);
printf("First cmd: %ldms\n", metrics.first_command_latency);
printf("Memory: %ldKB\n", metrics.baseline_memory);

// Get diagnostic info
char* diags = ios_getDiagnosticInfo();
printf("%s\n", diags);
free(diags);
```

### Command Preloading
```c
// Preload single command
ios_preloadCommand("ls", NULL);

// Preload multiple commands with progress
const char* cmds[] = {"ls", "cat", "grep", "sed", NULL};
ios_preloadCommands(cmds, 3, progress_callback);

// Clear caches (don't unload)
ios_clearCommandCaches();
```

### Context Type Enum
```c
// Replace string context with flags
ios_setContextType(IOS_CONTEXT_NORMAL | IOS_CONTEXT_INTERACTIVE);

// Check context
if (ios_hasContextFlag(IOS_CONTEXT_IN_EXTENSION)) {
    // Handle extension context
}

// Get all flags
uint32_t flags = ios_getContextFlags();
```

### Window Resize Coalescing
```c
// Set window size with debounce
ios_setWindowSizeCoalesced(width, height, sessionId, 100);

// Check for pending resize
if (ios_isPendingWindowResize(NULL)) {
    // Wait or handle pending resize
}

// Force immediate resize
ios_flushWindowResize(NULL);
```

### Path Caching
```c
// Get cached path bookmark (automatic caching)
const char* bookmarked = ios_getCachedPathBookmark("/private/var/...");
// Returns: "~/Documents/..." (cached)

// Invalidate specific path
ios_invalidatePathCache("/private/var/...");

// Clear entire cache
ios_invalidatePathCache(NULL);

// Get cache statistics
ios_getPathCacheStats(&hits, &misses, &size);
```

### Command Hooks
```c
// Register pre-execution hook
int my_pre_execute(const char* cmd, char** argv) {
    printf("About to execute: %s\n", cmd);
    return 0; // Allow execution
}
ios_registerHook(IOS_HOOK_PRE_EXECUTE, my_pre_execute);

// Register post-execution hook
void my_post_execute(const char* cmd, int status) {
    printf("Command finished with status: %d\n", status);
}
ios_registerHook(IOS_HOOK_POST_EXECUTE, my_post_execute);

// Check if hook registered
if (ios_isHookRegistered(IOS_HOOK_PRE_EXECUTE)) {
    // Hook is active
}

// Unregister hook
ios_unregisterHook(IOS_HOOK_PRE_EXECUTE);
```

### Thread Safety
```c
// Lock session list for multi-session operations
ios_lock_session_list();
// ... do multi-session work ...
ios_unlock_session_list();

// Try lock with timeout
if (ios_trylock_session_list(1000) == 0) {  // 1 second timeout
    // Got lock
    ios_unlock_session_list();
}
```

### Output Buffering
```c
// Set custom buffer size (e.g., for high-output commands)
ios_setOutputBufferSize(256 * 1024, sessionId);  // 256KB

// Enable adaptive buffering
ios_setAdaptiveBuffering(1, sessionId);

// Set output rate limit (backpressure)
ios_setOutputRateLimit(1024 * 1024, sessionId);  // 1MB/sec
```

---

## Common Implementation Patterns

### Pattern 1: Performance-Critical Section
```c
// Measure execution time
#include <time.h>

clock_t start = clock();
// ... critical code ...
clock_t end = clock();
double elapsed = (double)(end - start) / CLOCKS_PER_SEC * 1000;

// Log if slow
if (elapsed > 100) {
    fprintf(thread_stderr, "Slow operation: %.2fms\n", elapsed);
}
```

### Pattern 2: Command with Hook Support
```c
// In command implementation
int my_command_main(int argc, char** argv) {
    // Pre-execution hook
    if (ios_isHookRegistered(IOS_HOOK_PRE_EXECUTE)) {
        // Hook will be called by framework
    }
    
    // Command logic
    int status = perform_command();
    
    // Post-execution hook
    if (ios_isHookRegistered(IOS_HOOK_POST_EXECUTE)) {
        // Hook will be called by framework
    }
    
    return status;
}
```

### Pattern 3: Thread-Safe Session Operation
```c
void safe_multi_session_operation(void) {
    ios_lock_session_list();
    
    // Do multi-session work here
    ios_switchSession(session1);
    ios_system("command1");
    
    ios_switchSession(session2);
    ios_system("command2");
    
    ios_unlock_session_list();
}
```

### Pattern 4: Preload on Startup
```c
// In app initialization
- (void)applicationDidFinishLaunching {
    // Initialize system
    initializeEnvironment();
    
    // Preload common commands
    const char* preload[] = {"ls", "cat", "grep", NULL};
    ios_preloadCommands(preload, 3, 
        ^(int index, const char* cmd) {
            NSLog(@"Preloaded: %s", cmd);
        });
}
```

---

## Performance Benchmarking Snippet

```c
// Add to your test code
void benchmark_operation(const char* name, void (*operation)(void)) {
    ios_enablePerformanceMonitoring(1);
    
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    operation();
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    
    double elapsed = (end.tv_sec - start.tv_sec) * 1000.0 +
                     (end.tv_nsec - start.tv_nsec) / 1000000.0;
    
    printf("Benchmark: %s = %.2f ms\n", name, elapsed);
    
    ios_performance_metrics_t metrics = ios_getPerformanceMetrics(NULL);
    printf("  Commands: %lu\n", metrics.commands_executed);
    printf("  Memory: %lu KB\n", metrics.baseline_memory);
}

// Usage
void test_ls(void) { ios_system("ls -la"); }
benchmark_operation("ls -la", test_ls);
```

---

## Testing Checklist (Quick Version)

### Before Each Build
- [ ] Command execution works (test: `ls`, `pwd`, `echo`)
- [ ] I/O redirection works (test: `ls > /tmp/test.txt`)
- [ ] Exit codes correct
- [ ] No memory leaks (test with -fsanitize=address)

### Before Each Release
- [ ] All unit tests pass (>95%)
- [ ] Performance benchmarks meet targets
- [ ] Device compatibility verified (6+ devices)
- [ ] Documentation updated
- [ ] Git tag created

### During Development
- [ ] Profile regularly with Instruments
- [ ] Run tests on low-memory devices (4GB)
- [ ] Check for regressions in baseline operations
- [ ] Monitor for thread safety issues

---

## Common Issues & Quick Fixes

### Issue 1: First Command Slow
**Check**: Is preloading enabled?
```c
// Add to initialization
ios_preloadCommand("ls", NULL);
```

### Issue 2: Memory Growing
**Check**: Is cache being cleared?
```c
// Add periodic cleanup
ios_clearAllCaches();
```

### Issue 3: Multi-Session Crashes
**Check**: Are you using locks?
```c
// Wrap multi-session code in:
ios_lock_session_list();
// ... work ...
ios_unlock_session_list();
```

### Issue 4: Slow Path Resolution
**Check**: Is path caching enabled?
```c
// Should be automatic, verify with:
unsigned long hits, misses;
ios_getPathCacheStats(&hits, &misses, NULL);
```

### Issue 5: High CPU Usage
**Check**: Is there output rate limiting?
```c
// Add rate limiting for high-output commands
ios_setOutputRateLimit(5 * 1024 * 1024, sessionId);
```

---

## File Organization

```
ios_system/
├── Sources/IOSSystem/
│   ├── ios_system.h                    [Main header]
│   ├── ios_system.m                    [Implementation]
│   ├── ios_system_optimizations.h      [New optimizations header]
│   ├── ios_system_optimizations.c      [New optimizations impl]
│   ├── ios_error.h                     [Error handling]
│   ├── ios_system_stubs.m              [Stubs]
│   └── Resources/
│       ├── commandDictionary.plist     [Command definitions]
│       └── extraCommandsDictionary.plist
│
├── Tests/
│   └── IOSSystemTests/
│       ├── FunctionalityTests.swift    [Unit tests]
│       ├── PerformanceTests.swift      [Perf tests]
│       └── IntegrationTests.swift      [Integration]
│
├── OPTIMIZATION_REPORT.md              [Technical analysis]
├── IMPLEMENTATION_ROADMAP.md           [Implementation plan]
├── TESTING_GUIDE.md                    [Test procedures]
├── OPTIMIZATION_SUMMARY.md             [Executive summary]
└── DEVELOPER_QUICK_REFERENCE.md        [This file]
```

---

## Key Metrics to Track

### During Implementation
```c
// Always measure these
struct {
    unsigned long command_execution_time;  // Per command
    unsigned long framework_load_time;     // First load
    unsigned long context_switch_time;     // Session switching
    unsigned long path_resolution_time;    // Path operations
    unsigned long memory_allocated;        // Session memory
    int cache_hits;                        // Cache effectiveness
    int cache_misses;
} perf_metrics;
```

### Reporting Template
```
Performance Report - Week N
===========================
Baseline Metric              Current        Target      Status
─────────────────────────────────────────────────────────────
First command latency        150ms          <100ms      🟡 Close
Session memory               75KB           <70KB       🟢 Good
Context switch speed         2ms            <2ms        🟢 Good
Cache hit rate               85%            >80%        🟢 Good
Device compatibility         6/8            8/8         🟡 Close
Test pass rate               97%            >95%        🟢 Good
```

---

## Resources & Links

### In This Project
- **OPTIMIZATION_REPORT.md** - 11 recommendations with analysis
- **IMPLEMENTATION_ROADMAP.md** - Phase-by-phase breakdown
- **TESTING_GUIDE.md** - Complete test specification
- **OPTIMIZATION_SUMMARY.md** - Executive overview

### External References
- [Xcode Instruments Guide](https://developer.apple.com/xcode/instruments/)
- [iOS Performance Best Practices](https://developer.apple.com/videos/)
- [Thread-Safe Coding Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/)
- [Memory Management in Objective-C](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/)

---

## Contact & Support

### For Questions About:
- **Architecture/Design**: See OPTIMIZATION_REPORT.md, section 1
- **Implementation details**: See IMPLEMENTATION_ROADMAP.md, phase X
- **Testing procedures**: See TESTING_GUIDE.md, section X
- **Timeline**: See IMPLEMENTATION_ROADMAP.md, timeline summary
- **Success criteria**: See OPTIMIZATION_SUMMARY.md, success metrics

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Mar 2026 | Initial release with 4-phase roadmap |

---

**Keep this reference handy during implementation!**  
Print the [PDF version](./DEVELOPER_QUICK_REFERENCE.pdf) if available.
