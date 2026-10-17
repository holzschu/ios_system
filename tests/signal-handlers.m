#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <unistd.h>

static void host_handler(int number) { (void)number; }
static void timeout_handler(int number) { (void)number; _Exit(124); }
static const char *session = "signal-handler-check";

static void run_command(const char *command) {
    pid_t pid = ios_fork();
    ios_system(command);
    ios_waitpid(pid);
}

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timeout_handler);
        alarm(10);
        initializeEnvironment();
        ios_switchSession(session);
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        ios_setStreams(input, output, error);
        joinMainThread = true;
        const int numbers[] = {SIGINT, SIGUSR1, SIGWINCH};
        for (unsigned i = 0; i < sizeof(numbers) / sizeof(numbers[0]); i++) {
            int number = numbers[i];
            struct sigaction expected = {0}, actual = {0};
            sigemptyset(&expected.sa_mask);
            sigaddset(&expected.sa_mask, SIGUSR2);
            expected.sa_handler = host_handler;
            expected.sa_flags = SA_RESTART;
            if (sigaction(number, &expected, NULL)) return 2;
            char command[64];
            snprintf(command, sizeof(command), "signal-handler %d", number);
            run_command(command);
            if (sigaction(number, NULL, &actual) || actual.sa_handler != host_handler ||
                !(actual.sa_flags & SA_RESTART) || !sigismember(&actual.sa_mask, SIGUSR2)) {
                dprintf(STDERR_FILENO, "FAIL: disposition not restored for signal %d (handler=%p expected=%p flags=%x mask=%d)\n", number, actual.sa_handler, host_handler, actual.sa_flags, sigismember(&actual.sa_mask, SIGUSR2));
                return 1;
            }
            raise(number);
        }
        // An ignored signal remains ignored after a command temporarily owns it.
        signal(SIGINT, SIG_IGN);
        run_command("signal-handler 2");
        struct sigaction actual = {0};
        sigaction(SIGINT, NULL, &actual);
        if (actual.sa_handler != SIG_IGN) return 1;
        // A command that leaves dispositions alone must preserve the host callback.
        signal(SIGUSR1, host_handler);
        run_command("signal-handler");
        sigaction(SIGUSR1, NULL, &actual);
        if (actual.sa_handler != host_handler) return 1;
        alarm(0);
        dprintf(STDERR_FILENO, "PASS: command handlers restored; masks, flags and unrelated handlers preserved\n");
        return 0;
    }
}
