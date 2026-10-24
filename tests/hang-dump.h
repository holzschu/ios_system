// Shared by the tests that bound a hang with an alarm: print the stacks of every thread before exiting, so a
// stuck wait or lock shows its owner and a slow run shows threads still moving.
#include <spawn.h>
#include <unistd.h>

extern char **environ;

static void dumpStacksAndExit(void) {
    char target[16];
    snprintf(target, sizeof(target), "%d", getpid());
    char *arguments[] = {"sample", target, "1", NULL};
    pid_t child;
    // sample writes to stdout, which the test runner keeps. ios_system replaces waitpid, so wait for sample by time.
    posix_spawn(&child, "/usr/bin/sample", NULL, NULL, arguments, environ);
    sleep(15);
    _Exit(124);
}
