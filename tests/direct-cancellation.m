#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <errno.h>
#include <stdatomic.h>
#include <unistd.h>
#include <string.h>
static _Atomic int entered;
static volatile sig_atomic_t handled;
static void command_interrupt(int number) {
    (void)number;
    handled = 1;
}
int direct_cancel_main(int argc, char **argv) {
    if (argc > 1 && !strcmp(argv[1], "--handler")) {
        signal(SIGINT, command_interrupt);
        atomic_store(&entered, 1);
        for (int n = 0; n < 300 && !handled; n++) usleep(10000);
        return handled ? 23 : 7;
    }
    if (argc > 1) return 7;
    atomic_store(&entered, 1);
    sleep(3);
    return 7;
}
int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 2) return 2;
        alarm(8);
        initializeEnvironment();
        ios_switchSession("direct-cancel-public-consumer");
        ios_unsetenv("ASHELL_WORKER_COMMANDS");
        ios_unsetenv("ASHELL_HOST_COMMANDS");
        ios_setenv("PATH", argv[1], 1);
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        ios_setStreams(input, output, error);
        joinMainThread = false;
        replaceCommand(@"direct-cancel", @"direct_cancel_main", false);
        signal(SIGINT, SIG_IGN);
        pid_t pid = ios_fork();
        ios_system("direct-cancel");
        for (int n = 0; n < 200 && !atomic_load(&entered); n++) usleep(10000);
        if (!atomic_load(&entered)) return 2;
        int result = ios_interruptpid(pid);
        ios_waitpid(pid);
        int status = ios_getCommandStatus();
        int interrupted = !result && status == 130;
        pid = ios_fork();
        ios_system("direct-cancel --complete");
        ios_waitpid(pid);
        int following = ios_getCommandStatus();
        int absent = ios_interruptpid(pid);
        if (absent != ESRCH) return 1;
        atomic_store(&entered, 0);
        pid = ios_fork();
        ios_system("direct-cancel --handler");
        for (int n = 0; n < 200 && !atomic_load(&entered); n++) usleep(10000);
        if (!atomic_load(&entered)) return 2;
        int handlerResult = ios_killpid(pid, SIGINT);
        ios_waitpid(pid);
        int handlerStatus = ios_getCommandStatus();
        int handlerPassed = !handlerResult && handled && handlerStatus == 23;
        dprintf(1, "handler delivery result=%d handled=%d status=%d %s\n", handlerResult, handled, handlerStatus, handlerPassed ? "PASS" : "FAIL");
        dprintf(1, "direct interrupt result=%d status=%d following=%d %s\n", result, status, following, interrupted && following == 7 ? "PASS" : "FAIL");
        ios_setStreams(stdin, stdout, stderr);
        fclose(input);
        fclose(output);
        fclose(error);
        return interrupted && following == 7 && handlerPassed ? 0 : 1;
    }
}
