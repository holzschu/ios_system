// Register as a command in a disposable worker-enabled host.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <unistd.h>

int nested_environment_payload_main(int argc, char **argv) {
    const char *value = ios_getenv("NESTED_ENV_SENTINEL");
    bool passed = argc == 2 && getpid() != atoi(argv[1]) && value && !strcmp(value, "nested-command-value");
    fprintf(thread_stdout, "nested environment payload: %s\n", passed ? "PASS" : "FAIL");
    return passed ? 0 : 1;
}

int main(void) {
    alarm(30);
    FILE *output = tmpfile();
    if (!output) return 1;
    FILE *savedInput = thread_stdin, *savedOutput = thread_stdout, *savedError = thread_stderr;
    bool savedJoin = joinMainThread;
    ios_setenv("ASHELL_WORKER_COMMANDS", "nested-environment-payload", 1);
    ios_setenv("NESTED_ENV_SENTINEL", "nested-command-value", 1);
    ios_setStreams(savedInput, output, savedError);
    thread_stdout = NULL;
    joinMainThread = true;
    char command[128];
    snprintf(command, sizeof(command), "nested-environment-payload %d", getpid());
    int status = ios_system(command); // Deliberately do not reserve a child PID.
    fflush(output);
    rewind(output);
    char line[4096];
    bool seen = false;
    while (fgets(line, sizeof(line), output)) {
        if (!strcmp(line, "nested environment payload: PASS\n")) seen = true;
    }
    ios_setStreams(savedInput, savedOutput, savedError);
    thread_stdin = savedInput;
    thread_stdout = savedOutput;
    thread_stderr = savedError;
    joinMainThread = savedJoin;
    fclose(output);
    ios_unsetenv("ASHELL_WORKER_COMMANDS");
    ios_unsetenv("NESTED_ENV_SENTINEL");
    alarm(0);
    bool passed = status == 0 && seen;
    fprintf(savedOutput, "unforked nested worker environment: %s (status=%d payload=%d)\n", passed ? "PASS" : "FAIL", status, seen);
    return passed ? 0 : 1;
}
