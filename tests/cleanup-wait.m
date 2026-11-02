// A command in the middle of a pipeline that ends while the first command of the pipeline is still running waits
// for it before it releases its pid. That wait must sleep: it used to loop on the session with fflush, using a whole core.
// "hold | mid | skip" runs a first command that holds 2 seconds and a middle command that ends after 300 ms.
// A watchdog exits 124 when the test does not finish in 30 seconds.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#import "ios_error.h"
#include <pthread.h>
#include <signal.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <unistd.h>

int hold_main(int argc, char **argv) {
    usleep(2000 * 1000);
    return 0;
}

int skip_main(int argc, char **argv) {
    return 0;
}

int mid_main(int argc, char **argv) {
    usleep(300 * 1000); // the first command is the pipeline's root by now
    return 0;
}

static void timedOut(int signal) {
    fprintf(stderr, "cleanup-wait: FAIL, no end after 30 s\n");
    _Exit(124);
}

static double cpuSeconds(void) {
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    return usage.ru_utime.tv_sec + usage.ru_utime.tv_usec / 1e6 + usage.ru_stime.tv_sec + usage.ru_stime.tv_usec / 1e6;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(30);
        initializeEnvironment();
        ios_switchSession("cleanup-wait-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"hold", @"hold_main", false);
        replaceCommand(@"skip", @"skip_main", false);
        replaceCommand(@"mid", @"mid_main", false);
        joinMainThread = false;
        double before = cpuSeconds();
        ios_system("hold | mid | skip");
        sleep(3); // the first command ends after 2 s
        double cpu = cpuSeconds() - before;
        // A sleeping wait costs a few milliseconds; the loop cost about 2 s, one core for as long as the first command ran.
        if (cpu > 0.5) {
            fprintf(stderr, "cleanup-wait: FAIL, cpu=%.2fs in 3 s, the ending command spun\n", cpu);
            return 1;
        }
        fprintf(stderr, "cleanup-wait: cpu=%.2fs in 3 s PASS\n", cpu);
        return 0;
    }
}
