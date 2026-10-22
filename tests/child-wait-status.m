#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>

extern void ios_exit(int status);
static int observedA, observedB;

int child_status_fixture(int argc, char **argv) {
    if (argc != 2 && argc != 3) return 99;
    int result = atoi(argv[1]);
    if (argc == 3) {
        ios_waitpid(atoi(argv[2]));
        ios_exit(result);
    }
    return result;
}

int parent_status_fixture(int argc, char **argv) {
    pid_t first = ios_fork();
    ios_system("child-status 7");
    pid_t second = ios_fork();
    char command[64];
    snprintf(command, sizeof(command), "child-status 23 %d", first);
    ios_system(command);
    int firstStatus = 0, secondStatus = 0;
    ios_full_waitpid(second, &secondStatus, 0);
    ios_full_waitpid(first, &firstStatus, 0);
    observedA = WIFEXITED(firstStatus) ? WEXITSTATUS(firstStatus) : -1;
    observedB = WIFEXITED(secondStatus) ? WEXITSTATUS(secondStatus) : -1;
    return observedA == 7 && observedB == 23 ? 0 : 1;
}

static void timedOut(int number) { _Exit(124); }

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(10);
        initializeEnvironment();
        ios_switchSession("native-child-status");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"child-status", @"child_status_fixture", false);
        replaceCommand(@"parent-status", @"parent_status_fixture", false);
        joinMainThread = true;
        int result = ios_system("parent-status");
        dprintf(STDERR_FILENO, "child A expected=7 observed=%d; child B expected=23 observed=%d: %s\n", observedA, observedB, result == 0 ? "PASS" : "FAIL");
        alarm(0);
        return result == 0 ? 0 : 1;
    }
}
