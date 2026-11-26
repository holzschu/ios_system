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
        ios_setStreams(stdin, stdout, stderr);
        ios_settty(stdin);
        thread_stdin = stdin;
        thread_stdout = stdout;
        thread_stderr = stderr;
        int status = ios_system(argv[3]);
        ios_closeSession(session);
        return status;
    }
}
