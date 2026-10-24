// Several threads start short commands behind ios_fork while other commands end. A command that
// ends must not move current_pid under a thread that has just forked: the new command's slot would
// stay "not started" for ever and its ios_waitpid would never return.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include "hang-dump.h"
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <unistd.h>

#define THREADS 8
#define ROUNDS 400

int tick_main(int argc, char **argv) {
    return 0;
}

static atomic_int finished;

static void *worker(void *unused) {
    for (int i = 0; i < ROUNDS; i++) {
        pid_t pid = ios_fork();
        ios_system("tick");
        ios_waitpid(pid);
    }
    atomic_fetch_add(&finished, 1);
    return NULL;
}

static void timedOut(int signal) {
    fprintf(stderr, "concurrent-fork: FAIL, %d of %d threads finished, ios_waitpid never returned\n", atomic_load(&finished), THREADS);
    dumpStacksAndExit();
}

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(120);
        initializeEnvironment();
        ios_switchSession("concurrent-fork-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"tick", @"tick_main", false);
        joinMainThread = false;
        pthread_t threads[THREADS];
        for (int t = 0; t < THREADS; t++) pthread_create(&threads[t], NULL, worker, NULL);
        for (int t = 0; t < THREADS; t++) pthread_join(threads[t], NULL);
        alarm(0);
        fprintf(stderr, "concurrent-fork: %d threads x %d commands PASS\n", THREADS, ROUNDS);
        return 0;
    }
}
