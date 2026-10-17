// Reselecting an existing session must preserve its caller-installed streams.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <unistd.h>

int selected_stream_main(int argc, char **argv) {
    return fputs("SESSION\n", thread_stdout) == EOF ? 1 : 0;
}

static void timedOut(int signal) { _Exit(124); }

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(5);
        initializeEnvironment();
        const char *first = "selected-stream-first", *second = "selected-stream-second";
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        ios_switchSession(first);
        ios_setStreams(input, output, error);
        int before = ios_getstdin();
        ios_switchSession(second);
        ios_switchSession(first);
        int after = ios_getstdin();
        replaceCommand(@"selected-stream", @"selected_stream_main", false);
        thread_stdin = thread_stdout = thread_stderr = NULL;
        joinMainThread = true;
        ios_system("selected-stream");
        rewind(output);
        char actual[32] = {0};
        size_t length = fread(actual, 1, sizeof(actual) - 1, output);
        BOOL passed = before == fileno(input) && after == before && length == 8 && !strcmp(actual, "SESSION\n");
        ios_setStreams(stdin, stdout, stderr);
        thread_stdin = stdin;
        thread_stdout = stdout;
        thread_stderr = stderr;
        ios_closeSession(first);
        ios_closeSession(second);
        if (fclose(input) || fclose(output) || fclose(error)) return 1;
        alarm(0);
        dprintf(STDERR_FILENO, "selected session streams: before=%d after=%d bytes=%zu %s\n", before, after, length, passed ? "PASS" : "FAIL");
        return passed ? 0 : 1;
    }
}
