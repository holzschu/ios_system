// More commands than pid slots (127) start at once. The callers beyond the limit must wait for a command to end
// and then run; they must not spin on the pid table (which also kept the ending commands from freeing a slot).
// 200 threads each run ios_fork, ios_system("hold"), ios_waitpid. "hold" blocks until the test releases it, so
// while the table is full nothing ends, and the test can measure what the 73 waiting callers cost in CPU.
// A watchdog exits 124, with the stacks of all threads, when nothing has moved for 10 seconds.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include "hang-dump.h"
#import "ios_error.h"
#include <pthread.h>
#include <stdatomic.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <unistd.h>

#define THREADS 200
#define PIDS 127

static atomic_int launched, started, finished;
static pthread_mutex_t releaseLock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t releaseSignal = PTHREAD_COND_INITIALIZER;
static int released;

int hold_main(int argc, char **argv) {
    atomic_fetch_add(&started, 1);
    pthread_mutex_lock(&releaseLock);
    while (!released) pthread_cond_wait(&releaseSignal, &releaseLock);
    pthread_mutex_unlock(&releaseLock);
    return 0;
}

static void *worker(void *cookie) {
    atomic_fetch_add(&launched, 1);
    pid_t pid = ios_fork();
    ios_system("hold");
    ios_waitpid(pid);
    atomic_fetch_add(&finished, 1);
    return NULL;
}

static void *watchdog(void *cookie) {
    int last = -1, still = 0;
    while (1) {
        sleep(1);
        int now = atomic_load(&launched) + atomic_load(&started) + atomic_load(&finished);
        still = (now == last) ? still + 1 : 0;
        last = now;
        if (still >= 10) {
            fprintf(stderr, "pid-admission: FAIL, %d of %d commands finished, no progress for 10 s; stacks follow\n", atomic_load(&finished), THREADS);
            dumpStacksAndExit();
        }
    }
    return NULL;
}

static double seconds(struct timeval t) { return t.tv_sec + t.tv_usec / 1e6; }

static double cpuSeconds(void) {
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    return seconds(usage.ru_utime) + seconds(usage.ru_stime);
}

int main(int argc, char **argv) {
    @autoreleasepool {
        initializeEnvironment();
        ios_switchSession("pid-admission-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"hold", @"hold_main", false);
        joinMainThread = false;
        pthread_t guard;
        pthread_create(&guard, NULL, watchdog, NULL);
        struct timeval start, end;
        gettimeofday(&start, NULL);
        pthread_t threads[THREADS];
        for (long t = 0; t < THREADS; t++) pthread_create(&threads[t], NULL, worker, NULL);
        // Every pid is taken and the other callers are waiting for one. Nothing can end now.
        while (atomic_load(&started) < PIDS || atomic_load(&launched) < THREADS) usleep(10 * 1000);
        sleep(1);
        double before = cpuSeconds();
        sleep(1);
        double waiting = cpuSeconds() - before;
        fprintf(stderr, "pid-admission: the 73 waiting callers used %.2fs of CPU in 1 s\n", waiting);
        pthread_mutex_lock(&releaseLock);
        released = 1;
        pthread_cond_broadcast(&releaseSignal);
        pthread_mutex_unlock(&releaseLock);
        for (int t = 0; t < THREADS; t++) pthread_join(threads[t], NULL);
        gettimeofday(&end, NULL);
        double wall = seconds(end) - seconds(start);
        // Sleeping callers use almost no CPU in a one second window. The caller that holds pid_mtx and spins on
        // the pid table uses a whole core.
        if (waiting > 0.5) {
            fprintf(stderr, "pid-admission: FAIL, waiting callers spin\n");
            return 1;
        }
        fprintf(stderr, "pid-admission: %d commands over %d pids, wall=%.1fs PASS\n", THREADS, PIDS, wall);
        return 0;
    }
}
