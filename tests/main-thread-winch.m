// ios_setWindowSize sends SIGWINCH to the main thread of a session (mainThreadId), which is the only way it reaches a
// command that is not the root command of its session, such as dash. A command that has already ended must never
// remain recorded as the main thread: the next command would not be recorded and would never see the signal.
// The test starts a quick command, then a long command named dash with a SIGWINCH handler, resizes the window and
// expects the handler to run on that command's thread. When the quick command's thread stays recorded, the long command is never recorded.
// main-thread-winch-slowcreate.c is a dylib that interposes pthread_create so that the caller returns 100 ms after the thread started:
// the quick command has ended by then, as happens now and then under load.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#import "ios_error.h"
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <unistd.h>

static atomic_int winch, started;
static pthread_t dashThread, winchThread;
static char sessionTag;

static void onWinch(int sig) {
    winchThread = pthread_self();
    atomic_store(&winch, 1);
}

int dashlong_main(int argc, char **argv) {
    dashThread = pthread_self();
    signal(SIGWINCH, onWinch);
    atomic_store(&started, 1);
    for (int i = 0; i < 300 && !atomic_load(&winch); i++) usleep(10000); // up to 3 s
    return 0;
}

int quick_main(int argc, char **argv) {
    return 0;
}

extern atomic_int delayCreate; // in main-thread-winch-slowcreate.c

static void *park(void *arg) {
    while (1) sleep(1);
    return NULL;
}

static void timedOut(int sig) {
    fprintf(stderr, "main-thread-winch: FAIL, no end after 120 s\n");
    _Exit(124);
}

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(120);
        initializeEnvironment();
        ios_switchSession(&sessionTag);
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"dash", @"dashlong_main", false);
        replaceCommand(@"quick", @"quick_main", false);
        joinMainThread = false;
        atomic_store(&delayCreate, 1);
        ios_system("quick");
        atomic_store(&delayCreate, 0);
        usleep(500 * 1000);
        // Threads that stay alive, so that the next command thread does not reuse the one that ended
        pthread_t parked;
        for (int i = 0; i < 8; i++) pthread_create(&parked, NULL, park, NULL);
        ios_system("dash");
        while (!atomic_load(&started)) usleep(1000);
        ios_setWindowSize(80, 24, &sessionTag);
        for (int i = 0; i < 100 && !atomic_load(&winch); i++) usleep(10000); // up to 1 s
        // The signal must reach the long command's own thread: a stale id names a thread started after the command ended, and that thread gets the signal.
        if (!atomic_load(&winch) || winchThread != dashThread) {
            fprintf(stderr, "main-thread-winch: FAIL, SIGWINCH %s\n", atomic_load(&winch) ? "was handled on another thread" : "never arrived");
            return 1;
        }
        fprintf(stderr, "main-thread-winch: PASS\n");
        alarm(0);
        return 0;
    }
}
