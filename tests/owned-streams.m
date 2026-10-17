// Caller-owned command streams must survive command cleanup.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dlfcn.h>
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>

// A registered shell command uses the same cleanup path as the built-in sh.
// Its streams belong to the embedding caller, rather than a pipeline.
int stream_shell_main(int argc, char **argv) {
    return fputs("command output\n", thread_stdout) == EOF ? 1 : 0;
}

static void timedOut(int signal) { _Exit(124); }

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(10);
        initializeEnvironment();
        ios_switchSession("owned-streams-probe");
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        int descriptors[] = {fileno(input), fileno(output), fileno(error)};
        // Resolve the additive API at runtime so the same executable can expose
        // the old cleanup behavior when run against an unmodified framework.
        int (*registerStreams)(FILE *, FILE *, FILE *, void **) = dlsym(RTLD_DEFAULT, "ashell_register_owned_streams");
        void (*waitStreams)(void *) = dlsym(RTLD_DEFAULT, "ashell_wait_owned_streams");
        void (*unregisterStreams)(void **) = dlsym(RTLD_DEFAULT, "ashell_unregister_owned_streams");
        void *registration = NULL;
        if (registerStreams && (!waitStreams || !unregisterStreams || registerStreams(input, output, error, &registration))) return 2;
        ios_setStreams(input, output, error);
        replaceCommand(@"sh", @"stream_shell_main", false);
        joinMainThread = true;
        ios_system("sh -c stream-fixture");
        if (waitStreams) waitStreams(registration);
        int openStreams = 0;
        for (int i = 0; i < 3; i++) openStreams += fcntl(descriptors[i], F_GETFD) >= 0;
        dprintf(STDERR_FILENO, "caller streams still open: %d/3 %s\n", openStreams, openStreams == 3 ? "PASS" : "FAIL");
        // Do not dereference a FILE that the old framework has already freed.
        if (openStreams != 3) return 1;
        if (fputs("caller output\n", output) == EOF || fflush(output)) return 1;
        rewind(output);
        char actual[64] = {0};
        size_t length = fread(actual, 1, sizeof(actual) - 1, output);
        BOOL passed = length == strlen("command output\ncaller output\n") && !strcmp(actual, "command output\ncaller output\n");
        if (unregisterStreams) unregisterStreams(&registration);
        ios_setStreams(stdin, stdout, stderr);
        if (fclose(input) || fclose(output) || fclose(error)) return 1;
        alarm(0);
        dprintf(STDERR_FILENO, "caller stream read/write/close: %s\n", passed ? "PASS" : "FAIL");
        return passed ? 0 : 1;
    }
}
