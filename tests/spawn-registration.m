// Register in a disposable host launched with the external OS scheduling interposer.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dlfcn.h>
#include <errno.h>
#include <string.h>
#include <pthread.h>
#include <sys/wait.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 2 && argc != 3) return 64;
    BOOL fail = argc == 3 && strcmp(argv[2], "fail") == 0;
    alarm(15);
    void (*completeBeforeStart)(int) = dlsym(RTLD_DEFAULT, "complete_pid_before_spawn_thread");
    if (!completeBeforeStart) return 2;
    pid_t older = ios_fork();
    ios_storeThreadId(pthread_self());
    if (fail) {
        void (*failBeforeStart)(int) = dlsym(RTLD_DEFAULT, "fail_spawn_thread_after_completion");
        if (!failBeforeStart) return 2;
        failBeforeStart(older);
    } else completeBeforeStart(older);
    char *home;
    if (asprintf(&home, "HOME=%s", argv[1]) < 0) return 1;
    char *environment[] = { home, NULL }, *command[] = { "sleep", "0", NULL };
    pid_t child = -1;
    int status = -1;
    int error = ios_posix_spawn(&child, command[0], NULL, NULL, command, environment);
    free(home);
    BOOL completed = ios_getThreadId(older) == 0;
    if (fail) {
        int (*failedPid)(void) = dlsym(RTLD_DEFAULT, "failed_spawn_pid");
        BOOL released = failedPid && ios_getThreadId(failedPid()) == 0;
        BOOL passed = completed && error == EAGAIN && child == -1 && released;
        fprintf(thread_stdout, "spawn thread failure after older PID completion: %s (completed=%d error=%d child=%d released=%d)\n", passed ? "PASS" : "FAIL", completed, error, child, released);
        alarm(0);
        return passed ? 0 : 1;
    }
    BOOL registered = !error && ios_getThreadId(child) != (pthread_t)-1;
    pid_t waited = 0;
    if (!error) for (int n = 0; n < 300 && waited == 0; n++) {
        waited = ios_wait4(child, &status, WNOHANG, NULL, NULL);
        if (!waited) usleep(10000);
    }
    BOOL passed = completed && registered && waited == child && WIFEXITED(status) && WEXITSTATUS(status) == 0;
    fprintf(thread_stdout, "spawn registration after older PID completion: %s (completed=%d registered=%d waited=%d child=%d status=%d)\n", passed ? "PASS" : "FAIL", completed, registered, waited, child, status);
    alarm(0);
    return passed ? 0 : 1;
}
