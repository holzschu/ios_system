// A command that waits in chdir while another command is ending can be cancelled (Ctrl-C, ios_kill). The cancel must
// not leave cleanup_mutex locked: cleanup_function of the cancelled command takes it again, and every later
// command start and end would block for ever. The test plays the ending command with ios_cleanupBegin/ios_cleanupEnd,
// cancels a command blocked in chdir, and then runs another command. A watchdog exits 124 when it never finishes.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#import "ios_error.h"
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <unistd.h>

extern void ios_cleanupBegin(void);
extern void ios_cleanupEnd(void);

static pthread_t cdThread;
static atomic_int cdStarted;

int cdwait_main(int argc, char **argv) {
    cdThread = pthread_self();
    atomic_store(&cdStarted, 1);
    chdir("."); // waits while a command is ending
    usleep(10000); // a cancellation point: the cancel arrives here once the wait is over
    return 0;
}

int skip_main(int argc, char **argv) {
    return 0;
}

static void timedOut(int signal) {
    fprintf(stderr, "cleanup-cancel: FAIL, no end after 20 s\n");
    _Exit(124);
}

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(20);
        initializeEnvironment();
        ios_switchSession("cleanup-cancel-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"cdwait", @"cdwait_main", false);
        replaceCommand(@"skip", @"skip_main", false);
        joinMainThread = false;
        ios_cleanupBegin(); // a command is ending
        ios_system("cdwait");
        while (!atomic_load(&cdStarted)) usleep(1000);
        usleep(500 * 1000); // cdwait is in chdir by now
        pthread_cancel(cdThread);
        usleep(300 * 1000);
        ios_cleanupEnd(); // hangs here when the cancelled command kept cleanup_mutex
        usleep(300 * 1000);
        pid_t pid = ios_fork();
        ios_system("skip");
        ios_waitpid(pid);
        fprintf(stderr, "cleanup-cancel: PASS\n");
        alarm(0);
        return 0;
    }
}
