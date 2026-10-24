// Register in a disposable worker-enabled host; argv[1] is the host HOME.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include "ios_spawn.h"
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 2) return 64;
    alarm(60);
    char original[PATH_MAX], observed[PATH_MAX], expected[PATH_MAX];
    if (!getcwd(original, sizeof(original))) return 1;
    NSString *base = [@(argv[1]) stringByAppendingPathComponent:[@"Documents/spawn-context-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    NSURL *first = [NSURL fileURLWithPath:[base stringByAppendingPathComponent:@"first"]];
    NSURL *second = [NSURL fileURLWithPath:[base stringByAppendingPathComponent:@"second"]];
    if (![NSFileManager.defaultManager createDirectoryAtURL:first withIntermediateDirectories:YES attributes:nil error:nil] ||
        ![NSFileManager.defaultManager createDirectoryAtURL:second withIntermediateDirectories:YES attributes:nil error:nil]) return 1;
    char *home;
    if (asprintf(&home, "HOME=%s", argv[1]) < 0) return 1;
    char *environment[] = { home, NULL };
    char *command[] = { "sleep", "1", NULL };
    pid_t pid = -1;
    int status = -1;
    ios_setDirectoryURL(first);
    int error = ios_posix_spawn(&pid, command[0], NULL, NULL, command, environment);
    ios_setDirectoryURL(second);
    if (!getcwd(expected, sizeof(expected))) return 1;
    BOOL passed = !error && ios_wait4(pid, &status, 0, NULL, NULL) == pid && WIFEXITED(status) && WEXITSTATUS(status) == 0 &&
        getcwd(observed, sizeof(observed)) && !strcmp(observed, expected);
    fprintf(thread_stdout, "spawn completion preserves parent cwd: %s\n", passed ? "PASS" : "FAIL");
    if (passed) {
        int parentStatus = ios_getCommandStatus();
        char *longCommand[] = { "sleep", "30", NULL };
        error = ios_posix_spawn(&pid, longCommand[0], NULL, NULL, longCommand, environment);
        int killed = error ? error : ios_killpid(pid, SIGTERM);
        pid_t waited = error ? -1 : ios_wait4(pid, &status, 0, NULL, NULL);
        int observedStatus = ios_getCommandStatus();
        passed = !error && !killed && waited == pid && WIFEXITED(status) &&
            WEXITSTATUS(status) == 128 + SIGTERM && observedStatus == parentStatus;
        if (!passed) fprintf(thread_stdout, "spawn=%d kill=%d wait=%d status=%d parent=%d observed=%d\n", error, killed, waited, status, parentStatus, observedStatus);
        fprintf(thread_stdout, "spawn cancellation preserves parent status: %s\n", passed ? "PASS" : "FAIL");
    }
    ios_setDirectoryURL([NSURL fileURLWithPath:@(original)]);
    [NSFileManager.defaultManager removeItemAtPath:base error:nil];
    free(home);
    alarm(0);
    return passed ? 0 : 1;
}
