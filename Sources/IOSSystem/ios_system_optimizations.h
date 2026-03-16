//
//  ios_system_optimizations.h
//  ios_system
//
//  Performance optimization interfaces for iOS CLI
//  Created as part of comprehensive CLI optimization initiative
//

#ifndef ios_system_optimizations_h
#define ios_system_optimizations_h

#include <stdio.h>
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// MARK: - Performance Monitoring
// ============================================================================

/**
 * Performance metrics structure for tracking CLI operations
 */
typedef struct {
    // Timing metrics (in milliseconds)
    unsigned long startup_time;              // App init to first command
    unsigned long first_command_latency;     // Time to execute first command
    unsigned long session_switch_latency;    // Context switch duration
    unsigned long command_parse_time;        // Time to parse command line
    unsigned long framework_load_time;       // dlopen/dlsym overhead
    
    // Memory metrics (in KB)
    unsigned long baseline_memory;           // Session baseline memory
    unsigned long peak_memory;               // Peak memory during session
    unsigned long command_cache_size;        // Size of result cache
    
    // Operation counts
    unsigned long commands_executed;         // Total commands run
    unsigned long framework_loads;           // Number of framework loads
    unsigned long cache_hits;                // Successful cache lookups
    unsigned long cache_misses;              // Failed cache lookups
    
    // Timing details
    unsigned long max_command_duration;      // Longest command execution
    unsigned long avg_command_duration;      // Average command time
    
    // Resource info
    int active_sessions;                     // Current session count
    int loaded_frameworks;                   // Number of loaded frameworks
    
} ios_performance_metrics_t;

/**
 * Get current performance metrics for a session
 * @param sessionId Session identifier (NULL for current)
 * @return Performance metrics structure
 */
extern ios_performance_metrics_t ios_getPerformanceMetrics(const void* sessionId);

/**
 * Reset performance metrics for a session
 * @param sessionId Session identifier (NULL for current)
 */
extern void ios_resetPerformanceMetrics(const void* sessionId);

/**
 * Enable/disable performance monitoring
 * @param enabled Non-zero to enable, zero to disable
 */
extern void ios_enablePerformanceMonitoring(int enabled);

// ============================================================================
// MARK: - Command Preloading
// ============================================================================

/**
 * Preload a command framework into memory
 * Reduces latency for first invocation of the command
 * 
 * @param command Command name (e.g., "ls", "cat", "grep")
 * @param progress_callback Optional callback showing progress (0-100)
 * @return 0 on success, -1 on failure
 */
extern int ios_preloadCommand(const char* command, 
                              void (*progress_callback)(int percent));

/**
 * Preload multiple commands with progress tracking
 * 
 * @param commands Array of command names
 * @param count Number of commands
 * @param progress_callback Called as: progress_callback(command_index, command_name)
 * @return Number of successfully preloaded commands
 */
extern int ios_preloadCommands(const char** commands, int count,
                               void (*progress_callback)(int, const char*));

/**
 * Get list of preloadable commands
 * @return NULL-terminated array of command names
 */
extern const char** ios_preloadableCommands(void);

/**
 * Clear command caches (frameworks stay loaded)
 */
extern void ios_clearCommandCaches(void);

// ============================================================================
// MARK: - Path Resolution Caching
// ============================================================================

/**
 * Path cache entry for optimized path resolution
 */
typedef struct {
    const char* full_path;      // Original full path
    const char* bookmarked;     // Bookmarked representation
    unsigned long access_count; // Number of accesses
    time_t last_access;         // Last access time
} ios_path_cache_entry_t;

/**
 * Get path from cache or resolve it
 * Returns bookmarked version of path (e.g., ~Documents/file.txt)
 * 
 * @param full_path Full file system path
 * @return Bookmarked path (cached result)
 */
extern const char* ios_getCachedPathBookmark(const char* full_path);

/**
 * Invalidate path cache for a specific path
 * @param path Path to invalidate (NULL to clear entire cache)
 */
extern void ios_invalidatePathCache(const char* path);

/**
 * Get cache statistics
 * @return Hit count, miss count, cache size in bytes
 */
extern void ios_getPathCacheStats(unsigned long* hits, 
                                  unsigned long* misses,
                                  unsigned long* size_bytes);

// ============================================================================
// MARK: - Context Type Enum (replaces string-based context)
// ============================================================================

typedef enum {
    IOS_CONTEXT_NORMAL = 0x0,           // Normal command execution
    IOS_CONTEXT_IN_EXTENSION = 0x1,     // Running in app extension
    IOS_CONTEXT_FOREGROUND = 0x2,       // App is in foreground
    IOS_CONTEXT_BACKGROUND = 0x4,       // App is in background
    IOS_CONTEXT_INTERACTIVE = 0x8,      // Interactive terminal session
    IOS_CONTEXT_SCRIPTED = 0x10,        // Script/batch execution
    IOS_CONTEXT_LOW_MEMORY = 0x20,      // Under memory pressure
} ios_context_type_t;

/**
 * Set context flags (replaces string-based ios_setContext)
 * @param flags Combination of ios_context_type_t flags
 */
extern void ios_setContextType(uint32_t flags);

/**
 * Check if context has flag
 * @param flag Single flag to check
 * @return Non-zero if flag is set
 */
extern int ios_hasContextFlag(ios_context_type_t flag);

/**
 * Get current context flags
 * @return Current context flags
 */
extern uint32_t ios_getContextFlags(void);

// ============================================================================
// MARK: - Window Resize Event Coalescing
// ============================================================================

/**
 * Set window size with event coalescing
 * Debounces rapid resize events (e.g., during device rotation)
 * 
 * @param width Terminal width in columns
 * @param height Terminal height in rows
 * @param sessionId Session identifier (NULL for current)
 * @param debounce_ms Debounce delay in milliseconds (default 100)
 */
extern void ios_setWindowSizeCoalesced(int width, int height, 
                                       const void* sessionId,
                                       unsigned int debounce_ms);

/**
 * Check if a window resize event is pending
 * @param sessionId Session identifier (NULL for current)
 * @return Non-zero if resize is pending due to coalescing
 */
extern int ios_isPendingWindowResize(const void* sessionId);

/**
 * Flush pending window resize event immediately
 * @param sessionId Session identifier (NULL for current)
 */
extern void ios_flushWindowResize(const void* sessionId);

// ============================================================================
// MARK: - Command Hooks
// ============================================================================

/**
 * Hook types for command execution
 */
typedef enum {
    IOS_HOOK_PRE_EXECUTE,      // Before command execution
    IOS_HOOK_POST_EXECUTE,     // After command execution
    IOS_HOOK_ERROR_HANDLER,    // On command error
    IOS_HOOK_OUTPUT_FILTER,    // Filter/transform output
    IOS_HOOK_COMMAND_NOT_FOUND // Custom unknown command handler
} ios_hook_type_t;

/**
 * Hook function pointer types
 */
typedef int (*ios_pre_execute_hook_t)(const char* command, char** argv);
typedef void (*ios_post_execute_hook_t)(const char* command, int status);
typedef int (*ios_error_handler_hook_t)(const char* command, int error);
typedef int (*ios_output_filter_hook_t)(const char* line, FILE* output);

/**
 * Register a command execution hook
 * @param hook_type Type of hook to register
 * @param function Hook function pointer
 * @return 0 on success, -1 on failure
 */
extern int ios_registerHook(ios_hook_type_t hook_type, void* function);

/**
 * Unregister a command execution hook
 * @param hook_type Type of hook to unregister
 */
extern void ios_unregisterHook(ios_hook_type_t hook_type);

/**
 * Check if a hook is registered
 * @param hook_type Type of hook to check
 * @return Non-zero if hook is registered
 */
extern int ios_isHookRegistered(ios_hook_type_t hook_type);

// ============================================================================
// MARK: - Thread Safety & Locking
// ============================================================================

/**
 * Lock session list for multi-session operations
 * @return 0 on success, non-zero on error
 */
extern int ios_lock_session_list(void);

/**
 * Unlock session list
 * @return 0 on success, non-zero on error
 */
extern int ios_unlock_session_list(void);

/**
 * Try to lock session list with timeout
 * @param timeout_ms Timeout in milliseconds
 * @return 0 on success, ETIMEDOUT on timeout
 */
extern int ios_trylock_session_list(unsigned int timeout_ms);

// ============================================================================
// MARK: - Output Buffering Optimization
// ============================================================================

/**
 * Set output buffer size for a session
 * Larger buffers reduce system calls but use more memory
 * 
 * @param size Buffer size in bytes (recommended 256KB)
 * @param sessionId Session identifier (NULL for current)
 * @return 0 on success
 */
extern int ios_setOutputBufferSize(size_t size, const void* sessionId);

/**
 * Enable adaptive buffering
 * Automatically adjust buffer size based on output rate
 * 
 * @param enabled Non-zero to enable
 * @param sessionId Session identifier (NULL for current)
 */
extern void ios_setAdaptiveBuffering(int enabled, const void* sessionId);

/**
 * Set output rate limit
 * Prevents overwhelming slow consumers (e.g., TTY)
 * 
 * @param bytes_per_second Rate limit in bytes/sec (0 = unlimited)
 * @param sessionId Session identifier (NULL for current)
 */
extern void ios_setOutputRateLimit(unsigned int bytes_per_second, 
                                   const void* sessionId);

// ============================================================================
// MARK: - Diagnostic Functions
// ============================================================================

/**
 * Get detailed diagnostic information
 * @return Formatted string with metrics, must be freed by caller
 */
extern char* ios_getDiagnosticInfo(void);

/**
 * Write diagnostic information to file
 * @param filepath Path where to write diagnostics
 * @return 0 on success
 */
extern int ios_writeDiagnostics(const char* filepath);

/**
 * Enable verbose logging
 * @param enabled Non-zero to enable
 */
extern void ios_setVerboseLogging(int enabled);

/**
 * Clear all optimization caches
 */
extern void ios_clearAllCaches(void);

/**
 * Get current optimization state
 * @return Formatted string describing optimization state, must be freed by caller
 */
extern char* ios_getOptimizationState(void);

#ifdef __cplusplus
}
#endif

#endif /* ios_system_optimizations_h */
