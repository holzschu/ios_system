// Run as a registered command in a disposable worker-enabled host, with its HOME as argv[1].
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include "ios_spawn.h"
#include <signal.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 2) return 64;
    char *home;
    if (asprintf(&home, "HOME=%s", argv[1]) < 0) return 1;
    char *env[] = { home, NULL };
    char *cpu[] = { "awk", "BEGIN { for (i=0;i<5000000;i++) s+=sqrt(i); exit(s>0?0:1) }", NULL };
    pid_t pid;
    int status, available;
    struct rusage usage;
    alarm(30);
    int error = ios_posix_spawn(&pid, cpu[0], NULL, NULL, cpu, env);
    if (error) { fprintf(stderr, "CPU spawn failed: %d\n", error); return 1; }
    if (ios_wait4(pid, &status, 0, &usage, &available) != pid ||
        !WIFEXITED(status) || WEXITSTATUS(status) || !available ||
        (usage.ru_utime.tv_sec == 0 && usage.ru_utime.tv_usec == 0)) return 1;
    fprintf(stderr, "CPU child user time: %ld.%06d\n", usage.ru_utime.tv_sec, usage.ru_utime.tv_usec);
    char *sleep[] = { "sleep", "30", NULL };
    error = ios_posix_spawn(&pid, sleep[0], NULL, NULL, sleep, env);
    if (error || ios_killpid(pid, SIGKILL)) return 1;
    available = 1;
    if (ios_wait4(pid, &status, 0, &usage, &available) != pid || available ||
        !WIFEXITED(status) || WEXITSTATUS(status) != 137) return 1;
    free(home);
    alarm(0);
    fprintf(stderr, "spawn-rusage: CPU measured, killed child unavailable PASS\n");
    return 0;
}
