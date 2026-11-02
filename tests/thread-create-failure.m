// Force one OS thread creation failure, then reuse the public command API.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dlfcn.h>
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>

int failure_next_main(int argc, char **argv) {
    return fputs("NEXT\n", thread_stdout) == EOF ? 1 : 0;
}
static void savedHandler(int number) {}
static void timedOut(int number) { _Exit(124); }

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(10);
        initializeEnvironment();
        ios_switchSession("thread-create-failure");
        void (*failNext)(void) = dlsym(RTLD_DEFAULT, "fail_next_command_thread");
        int (*failureCount)(void) = dlsym(RTLD_DEFAULT, "command_thread_failure_count");
        if (!failNext || !failureCount) return 2;
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        int descriptors[] = {fileno(input), fileno(output), fileno(error)};
        void *registration = NULL;
        if (ashell_register_owned_streams(input, output, error, &registration)) return 2;
        ios_setStreams(input, output, error);
        replaceCommand(@"failure-next", @"failure_next_main", false);
        struct sigaction action = {0}, actual = {0};
        action.sa_handler = savedHandler;
        sigemptyset(&action.sa_mask);
        if (sigaction(SIGUSR1, &action, NULL)) return 2;
        joinMainThread = true;
        failNext();
        int failed = ios_system("failure-next");
        ashell_wait_owned_streams(registration);
        if (failed != 126 || failureCount() != 1) return 1;
        for (int i = 0; i < 3; i++) if (fcntl(descriptors[i], F_GETFD) < 0) return 1;
        if (sigaction(SIGUSR1, NULL, &actual) || actual.sa_handler != savedHandler) return 1;
        if (ios_system("failure-next")) return 1;
        ashell_wait_owned_streams(registration);
        rewind(output);
        char bytes[16] = {0};
        size_t length = fread(bytes, 1, sizeof(bytes), output);
        if (length != 5 || memcmp(bytes, "NEXT\n", 5)) return 1;
        ashell_unregister_owned_streams(&registration);
        ios_setStreams(stdin, stdout, stderr);
        if (fclose(input) || fclose(output) || fclose(error)) return 1;
        alarm(0);
        dprintf(STDERR_FILENO, "thread creation failure: status=126; streams, signal and next output: PASS\n");
        return 0;
    }
}
