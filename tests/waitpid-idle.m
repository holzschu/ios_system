// ios_waitpid must sleep until the command ends, not spin while it waits.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <time.h>
#include <unistd.h>

int nap_main(int argc, char **argv) {
    usleep(1500000);
    return 0;
}

static double seconds(clockid_t clock) {
    struct timespec now;
    clock_gettime(clock, &now);
    return now.tv_sec + now.tv_nsec / 1e9;
}

static void timedOut(int signal) { _Exit(124); }

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(20);
        initializeEnvironment();
        ios_switchSession("waitpid-idle-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"nap", @"nap_main", false);
        joinMainThread = false;
        pid_t pid = ios_fork();
        ios_system("nap");
        double wall = seconds(CLOCK_MONOTONIC);
        double cpu = seconds(CLOCK_PROCESS_CPUTIME_ID);
        ios_waitpid(pid);
        wall = seconds(CLOCK_MONOTONIC) - wall;
        cpu = seconds(CLOCK_PROCESS_CPUTIME_ID) - cpu;
        BOOL passed = wall > 0.5 && cpu < wall / 4;
        fprintf(stderr, "ios_waitpid: wall=%.2fs cpu=%.2fs %s\n", wall, cpu, passed ? "PASS" : "FAIL");
        alarm(0);
        return passed ? 0 : 1;
    }
}
