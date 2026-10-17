// Exercise detached command completion and an immediate relative write via ios_system.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "ios_system.h"
#include <stdatomic.h>
#include <signal.h>
#include <unistd.h>

static NSString *shellDirectory;
static NSString *commandDirectory;
static _Atomic bool delayRestore;
static _Atomic bool restored;
static BOOL (*changeDirectory)(id, SEL, NSString *);

// The only substituted boundary is Apple's filesystem call latency. Keep its
// real result and side effects; make the premature completion window reliable.
static BOOL slowDirectoryChange(id manager, SEL selector, NSString *path) {
    if (atomic_load(&delayRestore) && [path isEqualToString:shellDirectory]) {
        usleep(250000);
        atomic_store(&restored, true);
    }
    return changeDirectory(manager, selector, path);
}

int leave_cwd_main(int argc, char **argv) {
    if (![[NSFileManager defaultManager] changeCurrentDirectoryPath:commandDirectory]) return 1;
    atomic_store(&delayRestore, true);
    return 0;
}

int relative_write_main(int argc, char **argv) {
    FILE *file = fopen("next-command.txt", "w");
    if (!file) return 1;
    fputs("next command\n", file);
    return fclose(file) != 0;
}

static void timedOut(int signal) { _Exit(124); }

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 2) return 2;
        signal(SIGALRM, timedOut);
        alarm(10);
        NSFileManager *files = NSFileManager.defaultManager;
        shellDirectory = [NSString stringWithUTF8String:argv[1]];
        commandDirectory = [shellDirectory stringByAppendingPathComponent:@"command"];
        if (![files createDirectoryAtPath:commandDirectory withIntermediateDirectories:YES attributes:nil error:NULL]) return 2;
        if (![files changeCurrentDirectoryPath:shellDirectory]) return 2;
        Method method = class_getInstanceMethod(NSFileManager.class, @selector(changeCurrentDirectoryPath:));
        changeDirectory = (void *)method_setImplementation(method, (IMP)slowDirectoryChange);
        initializeEnvironment();
        ios_switchSession("cwd-order-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"leave-cwd", @"leave_cwd_main", false);
        replaceCommand(@"relative-write", @"relative_write_main", false);
        joinMainThread = false;
        pid_t pid = ios_fork();
        ios_system("leave-cwd");
        ios_waitpid(pid);
        if (ios_getCommandStatus() != 0) return 3;
        // ios_system also supports callers without synthetic fork. Unlike a
        // fresh ios_fork, this public entry does not wait on cleanup_counter.
        joinMainThread = true;
        ios_system("relative-write");
        if (ios_getCommandStatus() != 0) return 3;
        NSString *expected = [shellDirectory stringByAppendingPathComponent:@"next-command.txt"];
        NSString *wrong = [commandDirectory stringByAppendingPathComponent:@"next-command.txt"];
        BOOL passed = [files fileExistsAtPath:expected] && ![files fileExistsAtPath:wrong];
        // Let the first detached thread finish before the process exits.
        usleep(500000);
        if (!atomic_load(&restored)) return 3;
        fprintf(stderr, "relative write: shell=%d command=%d %s\n", [files fileExistsAtPath:expected], [files fileExistsAtPath:wrong], passed ? "PASS" : "FAIL");
        alarm(0);
        return passed ? 0 : 1;
    }
}
