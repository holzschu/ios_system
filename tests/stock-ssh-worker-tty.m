// Link against ios_system. Arguments: STOCK_COMMAND_REGISTRY foreground|pipe|stdout-file|stdin-file.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <errno.h>
#include <stdatomic.h>
#include <unistd.h>

struct pane_options {
    size_t size;
    int tty, separate_stderr, stderr_fd;
};
static _Atomic int observed_tty;

// Record the terminal advertised to the app's worker broker. Refuse admission
// here so the test needs no extension pool or private keys.
int ashell_worker_spawn_ex(const char *command, const char *cwd, unsigned cols, unsigned rows,
    const char *const *env, struct pane_options *options, int *fd, void **job) {
    if (options->size >= sizeof(*options)) atomic_store(&observed_tty, options->tty);
    return EIO;
}
int ashell_worker_poll(void *job, int *status) { return -ENOTSUP; }
int ashell_worker_close_stdin(void *job) { return ENOTSUP; }
int ashell_worker_cancel(void *job) { return ENOTSUP; }
void ashell_worker_release(void *job) {}

static BOOL expect_tty(const char *command, int expected) {
    atomic_store(&observed_tty, -1);
    int status = ios_system(command);
    int tty = atomic_load(&observed_tty);
    fprintf(stderr, "worker tty: %s status=%d tty=%d expected=%d\n", command, status, tty, expected);
    return status == 127 && tty == expected;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 3) return 64;
        const char *command;
        int expected = 1;
        if (!strcmp(argv[2], "foreground")) command = "ssh -V";
        else if (!strcmp(argv[2], "stdout-file")) command = "ssh -V > /dev/null";
        else if (!strcmp(argv[2], "pipe")) { command = "echo yes | ssh -V"; expected = 0; }
        else if (!strcmp(argv[2], "stdin-file")) { command = "ssh -V < /dev/null"; expected = 0; }
        else return 64;
        alarm(15);
        initializeEnvironment();
        if (addCommandList(@(argv[1]))) return 65;
        static char session[] = "stock-ssh-worker-tty";
        ios_switchSession(session);
        ios_setContext(session);
        ios_setStreams(stdin, stdout, stderr);
        ios_settty(stdin);
        thread_stdin = stdin;
        thread_stdout = stdout;
        thread_stderr = stderr;
        ios_setenv("ASHELL_WORKER_COMMANDS", "ssh", 1);
        joinMainThread = true;
        BOOL passed = expect_tty(command, expected);
        ios_closeSession(session);
        fprintf(stderr, "STOCK_SSH_WORKER_TTY_%s\n", passed ? "PASS" : "FAIL");
        return passed ? 0 : 1;
    }
}
