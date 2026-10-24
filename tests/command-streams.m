// Real commands must leave the embedding caller's borrowed streams open.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>

static void timedOut(int signal) { _Exit(124); }

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 3 && argc != 4) return 64;
        signal(SIGALRM, timedOut);
        alarm(10);
        initializeEnvironment();
        ios_switchSession("command-streams-probe");
        int pipefd[2];
        if (pipe(pipefd)) return 2;
        const char inputBytes[] = "one two\nthree\n";
        if (write(pipefd[1], inputBytes, sizeof(inputBytes) - 1) != sizeof(inputBytes) - 1) return 2;
        close(pipefd[1]);
        FILE *input = fdopen(pipefd[0], "r"), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        int descriptors[] = {fileno(input), fileno(output), fileno(error)};
        void *registration = NULL;
        if (ashell_register_owned_streams(input, output, error, &registration)) return 2;
        ios_setStreams(input, output, error);
        joinMainThread = true;
        int status = ios_system(argv[1]);
        ashell_wait_owned_streams(registration);
        int openStreams = 0;
        for (int i = 0; i < 3; i++) openStreams += fcntl(descriptors[i], F_GETFD) >= 0;
        dprintf(STDERR_FILENO, "%s: status=%d caller streams open=%d/3\n", argv[1], status, openStreams);
        if (openStreams != 3) return 1;
        fflush(output);
        rewind(output);
        char actual[256] = {0};
        size_t count = fread(actual, 1, sizeof(actual) - 1, output);
        BOOL passed = (argc == 4 ? status == atoi(argv[3]) : status == 0) && count == strlen(argv[2]) && !strcmp(actual, argv[2]);
        ashell_unregister_owned_streams(&registration);
        ios_setStreams(stdin, stdout, stderr);
        if (fclose(input) || fclose(output) || fclose(error)) return 1;
        alarm(0);
        dprintf(STDERR_FILENO, "%s: output=[%s] %s\n", argv[1], actual, passed ? "PASS" : "FAIL");
        return passed ? 0 : 1;
    }
}
