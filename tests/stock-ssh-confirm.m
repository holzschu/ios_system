// Run one Stock SSH command in a session with an a-Shell virtual terminal.
#import <Foundation/Foundation.h>
#import <ios_system/ios_system.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 4) return 64;
        alarm(15);
        int tty = open("/dev/tty", O_RDWR);
        if (tty >= 0 || errno != ENXIO) {
            if (tty >= 0) close(tty);
            fprintf(stderr, "The test requires /dev/tty to fail with ENXIO\n");
            return 65;
        }
        initializeEnvironment();
        NSError *error = addCommandList(@(argv[1]));
        if (error) {
            fprintf(stderr, "Cannot register Stock SSH: %s\n", error.localizedDescription.UTF8String);
            return 66;
        }
        if (setenv("SSH_HOME", argv[2], 1) || unsetenv("ASHELL_WORKER_COMMANDS")) return 67;
        static char session[] = "stock-ssh-confirm";
        joinMainThread = true;
        ios_switchSession(session);
        ios_setContext(session);
        FILE *input = stdin, *diagnostics = stderr;
        if (strncmp(argv[3], "ssh-keygen ", 11) == 0) {
            // App worker streams need not be the process's standard descriptors.
            int in = dup(STDIN_FILENO), err = dup(STDERR_FILENO);
            if (in < 0 || err < 0) return 68;
            input = fdopen(in, "r");
            diagnostics = fdopen(err, "w");
            if (!input || !diagnostics || !freopen("/dev/null", "r", stdin) ||
                !freopen("/dev/null", "w", stderr)) return 68;
        }
        ios_setStreams(input, stdout, diagnostics);
        ios_settty(input);
        thread_stdin = input;
        thread_stdout = stdout;
        thread_stderr = diagnostics;
        int status = ios_system(argv[3]);
        ios_closeSession(session);
        return status;
    }
}
