// Commands that run at the same time share libc's optind. Every command thread resets it at start, so one
// command's option parsing can move another's: the second command then skips its argument. Eight threads
// run two small commands that parse options and print their first operand, and check each answer.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include "hang-dump.h"
#import "ios_error.h"
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <sys/stat.h>
#include <unistd.h>

#define THREADS 8
#define ROUNDS 300

static int operand_main(int argc, char **argv) {
    int ch;
    while ((ch = getopt(argc, argv, "ab")) != -1) usleep(2000);
    fprintf(thread_stdout, "%s\n", argv[optind] ? argv[optind] : "(none)");
    fflush(thread_stdout);
    return 0;
}
int tapa_main(int argc, char **argv) { return operand_main(argc, argv); }
int tapb_main(int argc, char **argv) { return operand_main(argc, argv); }

static atomic_int wrong, finished;
static char directory[PATH_MAX];

static void check(const char *command, const char *output, const char *expected) {
    FILE *f = fopen(output, "r");
    char buffer[256] = "";
    if (f) { fread(buffer, 1, sizeof(buffer) - 1, f); fclose(f); }
    if (strcmp(buffer, expected) != 0) {
        if (atomic_fetch_add(&wrong, 1) < 3) fprintf(stderr, "concurrent-getopt: \"%s\" printed \"%s\", expected \"%s\"\n", command, buffer, expected);
    }
}

static void *worker(void *cookie) {
    long id = (long)cookie;
    char output[PATH_MAX], command[PATH_MAX * 2];
    snprintf(output, sizeof(output), "%s/out.%ld", directory, id);
    for (int i = 0; i < ROUNDS; i++) {
        pid_t pid = ios_fork();
        if (id % 2 == 0) {
            snprintf(command, sizeof(command), "tapa -a -b operand > %s", output);
            ios_system(command);
            ios_waitpid(pid);
            check(command, output, "operand\n");
        } else {
            snprintf(command, sizeof(command), "tapb operand > %s", output);
            ios_system(command);
            ios_waitpid(pid);
            check(command, output, "operand\n");
        }
    }
    atomic_fetch_add(&finished, 1);
    return NULL;
}

static void timedOut(int signal) {
    fprintf(stderr, "concurrent-getopt: FAIL, %d of %d threads finished\n", atomic_load(&finished), THREADS);
    dumpStacksAndExit();
}

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(120);
        initializeEnvironment();
        ios_switchSession("concurrent-getopt-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"tapa", @"tapa_main", false);
        replaceCommand(@"tapb", @"tapb_main", false);
        joinMainThread = false;
        snprintf(directory, sizeof(directory), "%s/concurrent-getopt-%d", getenv("TMPDIR") ?: "/tmp", getpid());
        mkdir(directory, 0700);
        pthread_t threads[THREADS];
        for (long t = 0; t < THREADS; t++) pthread_create(&threads[t], NULL, worker, (void *)t);
        for (int t = 0; t < THREADS; t++) pthread_join(threads[t], NULL);
        alarm(0);
        if (atomic_load(&wrong)) {
            fprintf(stderr, "concurrent-getopt: FAIL, %d of %d commands gave a wrong answer\n", atomic_load(&wrong), THREADS * ROUNDS);
            return 1;
        }
        fprintf(stderr, "concurrent-getopt: %d threads x %d commands PASS\n", THREADS, ROUNDS);
        return 0;
    }
}
