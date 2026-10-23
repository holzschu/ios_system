#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <unistd.h>

int main(void) {
    FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
    if (!input || !output || !error) return 2;
    FILE *savedInput = thread_stdin, *savedOutput = thread_stdout, *savedError = thread_stderr;
    alarm(10);
    joinMainThread = true;
    ios_system("unalias sh");
    ios_setStreams(input, output, error);
    thread_stdin = thread_stdout = thread_stderr = NULL;
    joinMainThread = true;
    int status = ios_system("sh -c 'echo x >&2'");
    if (status == 0) status = ios_system("sh -c 'echo y 1>&2'");
    fflush(output);
    fflush(error);
    rewind(output);
    rewind(error);
    char out[16] = {0}, err[16] = {0};
    size_t outLength = fread(out, 1, sizeof(out)-1, output);
    size_t errLength = fread(err, 1, sizeof(err)-1, error);
    BOOL passed = status == 0 && outLength == 0 && errLength == 4 && !strcmp(err, "x\ny\n");
    ios_setStreams(savedInput, savedOutput, savedError);
    thread_stdin = savedInput;
    thread_stdout = savedOutput;
    thread_stderr = savedError;
    fclose(input);
    fclose(output);
    fclose(error);
    alarm(0);
    fprintf(savedError, "sh stderr: status=%d stdout=%zu stderr=%zu %s\n", status, outLength, errLength, passed ? "PASS" : "FAIL");
    return passed ? 0 : 1;
}
