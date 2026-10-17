// Native pipe sessions must use real descriptor state without changing UI sessions.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dlfcn.h>
#include <signal.h>
#include <sys/socket.h>
#include <unistd.h>

static void timedOut(int signal) { _Exit(124); }

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(10);
        int sockets[2];
        if (socketpair(AF_UNIX, SOCK_STREAM, 0, sockets)) return 2;
        FILE *stream = fdopen(sockets[0], "r+");
        if (!stream) return 2;
        ios_switchSession("native-tty-probe");
        ios_setStreams(stream, stream, stream);
        thread_stdin = thread_stdout = thread_stderr = stream;
        int before = ios_isatty(STDIN_FILENO);
        void (*useNativeTTY)(bool) = dlsym(RTLD_DEFAULT, "ios_useNativeTTY");
        if (useNativeTTY) useNativeTTY(true);
        int input = ios_isatty(STDIN_FILENO);
        int output = ios_isatty(STDOUT_FILENO);
        int error = ios_isatty(STDERR_FILENO);
        int descriptor = ios_isatty(fileno(stream));
        if (useNativeTTY) useNativeTTY(false);
        int after = ios_isatty(STDIN_FILENO);
        BOOL passed = before == 1 && !input && !output && !error && !descriptor && after == 1;
        dprintf(STDERR_FILENO, "socket tty: default=%d native=%d/%d/%d descriptor=%d restored=%d %s\n", before, input, output, error, descriptor, after, passed ? "PASS" : "FAIL");
        ios_setStreams(stdin, stdout, stderr);
        thread_stdin = stdin;
        thread_stdout = stdout;
        thread_stderr = stderr;
        ios_closeSession("native-tty-probe");
        fclose(stream);
        close(sockets[1]);
        alarm(0);
        return passed ? 0 : 1;
    }
}
