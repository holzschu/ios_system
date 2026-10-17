// Cancellation must include descendants whose streams were all redirected.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dlfcn.h>
#include <signal.h>
#include <unistd.h>

static int readyPipe[2];

int owned_child_main(int argc, char **argv) {
    if (write(readyPipe[1], "READY", 5) != 5) return 1;
    sleep(60);
    fputs("CHILD_WAS_NOT_CANCELLED\n", thread_stdout);
    return 0;
}

int owned_parent_main(int argc, char **argv) {
    pid_t child = ios_fork();
    ios_system("owned-child < /dev/null > child-output.txt 2> child-error.txt");
    ios_waitpid(child);
    return 0;
}

int owned_next_main(int argc, char **argv) {
    return fputs("NEXT\n", thread_stdout) == EOF ? 1 : 0;
}

static void timedOut(int signal) {
    const char message[] = "owned command cancellation timed out\n";
    write(STDERR_FILENO, message, sizeof(message) - 1);
    _Exit(124);
}

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 2 || chdir(argv[1]) || pipe(readyPipe)) return 2;
        signal(SIGALRM, timedOut);
        alarm(5);
        initializeEnvironment();
        ios_switchSession("owned-cancellation-probe");
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        void *registration = NULL;
        if (ashell_register_owned_streams(input, output, error, &registration)) return 2;
        int (*cancelStreams)(void *) = dlsym(RTLD_DEFAULT, "ashell_cancel_owned_streams");
        ios_setStreams(input, output, error);
        replaceCommand(@"owned-parent", @"owned_parent_main", false);
        replaceCommand(@"owned-child", @"owned_child_main", false);
        replaceCommand(@"owned-next", @"owned_next_main", false);
        joinMainThread = false;
        pid_t parent = ios_fork();
        ios_system("owned-parent");
        char ready[5];
        size_t count = 0;
        while (count < sizeof(ready)) {
            ssize_t received = read(readyPipe[0], ready + count, sizeof(ready) - count);
            if (received <= 0) return 2;
            count += received;
        }
        if (memcmp(ready, "READY", sizeof(ready))) return 2;
        if (cancelStreams && cancelStreams(registration)) return 1;
        ios_waitpid(parent);
        ashell_wait_owned_streams(registration);
        ashell_unregister_owned_streams(&registration);
        if (ashell_register_owned_streams(input, output, error, &registration)) return 2;
        joinMainThread = true;
        ios_system("owned-next");
        ashell_wait_owned_streams(registration);
        ashell_unregister_owned_streams(&registration);
        rewind(output);
        char actual[32] = {0};
        size_t length = fread(actual, 1, sizeof(actual) - 1, output);
        BOOL passed = length == 5 && !strcmp(actual, "NEXT\n");
        ios_setStreams(stdin, stdout, stderr);
        if (fclose(input) || fclose(output) || fclose(error)) return 1;
        close(readyPipe[0]);
        close(readyPipe[1]);
        alarm(0);
        dprintf(STDERR_FILENO, "redirected child cancelled; next command exact output: %s\n", passed ? "PASS" : "FAIL");
        return passed ? 0 : 1;
    }
}
