// Register in a disposable worker-enabled host; pass its HOME as argv[1].
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dispatch/dispatch.h>
#include <signal.h>
#include <pthread.h>
#include <sys/wait.h>
#include <unistd.h>

static volatile sig_atomic_t interrupted;
static dispatch_semaphore_t ready;
static void receivedInterrupt(int number) { interrupted = 1; }
static void *ordinaryThread(void *unused) {
    sigset_t signals;
    sigemptyset(&signals);
    sigaddset(&signals, SIGINT);
    pthread_sigmask(SIG_UNBLOCK, &signals, NULL);
    ios_storeThreadId(pthread_self());
    dispatch_semaphore_signal(ready);
    for (int n = 0; n < 100 && !interrupted; n++) usleep(10000);
    return NULL;
}
int main(int argc, char **argv) {
    if (argc != 2) return 64;
    interrupted = 0;
    alarm(30);
    char *home;
    if (asprintf(&home, "HOME=%s", argv[1]) < 0) return 1;
    char *environment[] = { home, NULL }, *command[] = { "sleep", "0", NULL };
    pid_t child = -1;
    int status;
    int error = ios_posix_spawn(&child, command[0], NULL, NULL, command, environment);
    free(home);
    if (error || ios_wait4(child, &status, 0, NULL, NULL) != child || status) return 1;
    BOOL passed = NO;
    for (int n = 0; n < 256; n++) {
        pid_t candidate = ios_fork();
        if (candidate != child) { ios_storeThreadId(NULL); continue; }
        struct sigaction action = {0}, saved = {0};
        action.sa_handler = receivedInterrupt;
        sigemptyset(&action.sa_mask);
        if (sigaction(SIGINT, &action, &saved)) return 1;
        ready = dispatch_semaphore_create(0);
        pthread_t thread;
        if (pthread_create(&thread, NULL, ordinaryThread, NULL)) return 1;
        dispatch_semaphore_wait(ready, DISPATCH_TIME_FOREVER);
        BOOL registered = ios_getThreadId(candidate) == thread;
        int killed = ios_killpid(candidate, SIGINT);
        void *result = NULL;
        pthread_join(thread, &result);
        passed = registered && killed == 0 && interrupted && result != PTHREAD_CANCELED;
        fprintf(thread_stdout, "reused=%d child=%d kill=%d signal=%d cancelled=%d registered=%d\n", candidate, child, killed, interrupted, result == PTHREAD_CANCELED, registered);
        ios_releaseThreadId(candidate);
        sigaction(SIGINT, &saved, NULL);
        break;
    }
    fprintf(thread_stdout, "reused worker PID delivers ordinary-thread SIGINT: %s\n", passed ? "PASS" : "FAIL");
    alarm(0);
    return passed ? 0 : 1;
}
