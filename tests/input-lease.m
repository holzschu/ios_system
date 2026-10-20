// A command may borrow stdin without replacing its tree cancellation owner.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dlfcn.h>
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>

static int readyPipe[2];

int leased_input_main(int argc, char **argv) {
    if (write(readyPipe[1], "R", 1) != 1) return 1;
    char value;
    ssize_t count;
    while ((count = read(fileno(thread_stdin), &value, 1)) > 0)
        if (fputc(value, thread_stdout) == EOF) return 1;
    return count < 0 ? 1 : 0;
}

int leased_next_main(int argc, char **argv) {
    return fputs("NEXT\n", thread_stdout) == EOF ? 1 : 0;
}

static void timedOut(int signal) { _Exit(124); }

int main(int argc, char **argv) {
    @autoreleasepool {
        BOOL cancel = argc == 2 && !strcmp(argv[1], "cancel");
        if (argc > 2 || (argc == 2 && !cancel) || pipe(readyPipe)) return 2;
        signal(SIGALRM, timedOut);
        alarm(5);
        initializeEnvironment();
        ios_switchSession("input-lease-probe");
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        int descriptors[2];
        if (!input || !output || !error || pipe(descriptors)) return 2;
        FILE *leased = fdopen(descriptors[0], "r");
        if (!leased) return 2;
        void *tree = NULL, *lease = NULL;
        if (ashell_register_owned_streams(input, output, error, &tree)) return 2;
        int (*registerInput)(FILE *, void **) = dlsym(RTLD_DEFAULT, "ashell_register_command_input");
        if (registerInput && registerInput(leased, &lease)) return 2;
        ios_setStreams(leased, output, error);
        ios_settty(leased);
        replaceCommand(@"sh", @"leased_input_main", false);
        replaceCommand(@"leased-next", @"leased_next_main", false);
        joinMainThread = false;
        pid_t command = ios_fork();
        ios_system("sh -c input");
        char ready;
        if (read(readyPipe[0], &ready, 1) != 1 || ready != 'R') return 2;
        if (cancel) {
            if (ashell_cancel_owned_streams(tree)) return 1;
        } else if (write(descriptors[1], "INPUT\n", 6) != 6) return 2;
        if (!cancel && close(descriptors[1])) return 2;
        ios_waitpid(command);
        if (cancel && close(descriptors[1])) return 2;
        ashell_wait_owned_streams(tree);
        ashell_wait_owned_streams(lease);
        ashell_unregister_owned_streams(&lease);
        BOOL kept = fcntl(descriptors[0], F_GETFD) != -1;
        ios_setStreams(input, output, error);
        ios_settty(input);
        thread_stdin = input;
        thread_stdout = output;
        thread_stderr = error;
        if (kept && fclose(leased)) return 1;
        ashell_unregister_owned_streams(&tree);
        if (ashell_register_owned_streams(input, output, error, &tree)) return 2;
        joinMainThread = true;
        ios_system("leased-next");
        ashell_wait_owned_streams(tree);
        ashell_unregister_owned_streams(&tree);
        rewind(output);
        char actual[32] = {0};
        size_t length = fread(actual, 1, sizeof(actual) - 1, output);
        const char *expected = cancel ? "NEXT\n" : "INPUT\nNEXT\n";
        BOOL passed = registerInput && kept && length == strlen(expected) && !strcmp(actual, expected);
        ios_setStreams(stdin, stdout, stderr);
        if (fclose(input) || fclose(output) || fclose(error)) return 1;
        close(readyPipe[0]);
        close(readyPipe[1]);
        alarm(0);
        dprintf(STDERR_FILENO, "input %s, caller close and next command: %s (ABI=%d kept=%d bytes=%zu)\n", cancel ? "cancel" : "EOF", passed ? "PASS" : "FAIL", registerInput != NULL, kept, length);
        return passed ? 0 : 1;
    }
}
