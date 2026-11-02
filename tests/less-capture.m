#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <string.h>
#include <unistd.h>

static void timedOut(int signal) { _Exit(124); }

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(10);
        const char expected[] = "PAGER_CAPTURE_OK\n";
        char path[] = "/tmp/less-capture-XXXXXX";
        int fixture = mkstemp(path);
        if (fixture < 0 || write(fixture, expected, sizeof(expected) - 1) != sizeof(expected) - 1) return 2;
        close(fixture);
        initializeEnvironment();
        for (int round = 0; round < 2; round++) {
            for (int usePipe = 0; usePipe < 2; usePipe++) {
                int descriptors[2];
                if (usePipe && pipe(descriptors)) return 2;
                FILE *input = fopen("/dev/null", "r");
                FILE *output = usePipe ? fdopen(descriptors[1], "w") : tmpfile();
                if (!input || !output) return 2;
                const char *session = "lessCapture";
                ios_switchSession(session);
                ios_setContext(session);
                ios_setStreams(input, output, output);
                ios_useNativeTTY(true);
                char command[sizeof(path) + 8];
                snprintf(command, sizeof(command), "less %s", path);
                joinMainThread = false;
                pid_t pid = ios_fork();
                ios_system(command);
                ios_waitpid(pid);
                int status = ios_getCommandStatus();
                ios_releaseThreadId(pid);
                fflush(output);
                FILE *result;
                if (usePipe) {
                    fclose(output);
                    result = fdopen(descriptors[0], "r");
                } else {
                    rewind(output);
                    result = output;
                }
                if (!result) return 2;
                char bytes[128];
                size_t count = fread(bytes, 1, sizeof(bytes), result);
                bool passed = status == 0 && count == sizeof(expected) - 1 && !memcmp(bytes, expected, count);
                dprintf(2, "LESS_CAPTURE round=%d output=%s status=%d bytes=%zu %s\n", round + 1, usePipe ? "pipe" : "file", status, count, passed ? "PASS" : "FAIL");
                ios_closeSession(session);
                fclose(input);
                fclose(result);
                if (!passed) { unlink(path); return 1; }
            }
        }
        unlink(path);
        alarm(0);
        return 0;
    }
}
