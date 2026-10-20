// The WASM engine reads its reserved queue position after a host drain attempt.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dispatch/dispatch.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>

static dispatch_semaphore_t prepared, resume;
static int observed;
static void timed_out(int number) { _Exit(124); }

// Stand in only for the external WebAssembly engine; command dispatch is real.
int fixture_wasm(int argc, char **argv) {
    finishedPreparingWebAssemblyCommand();
    dispatch_semaphore_signal(prepared);
    dispatch_semaphore_wait(resume, DISPATCH_TIME_FOREVER);
    observed = webAssemblyCommandOrder();
    return 0;
}

void executeWebAssemblyCommands(void) {}

int main(void) {
    @autoreleasepool {
        signal(SIGALRM, timed_out);
        alarm(5);
        initializeEnvironment();
        ios_switchSession("wasm-order-test");
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        ios_setStreams(input, output, error);
        replaceCommand(@"wasm", @"fixture_wasm", false);
        prepared = dispatch_semaphore_create(0);
        resume = dispatch_semaphore_create(0);
        joinMainThread = false;
        pid_t pid = ios_fork();
        ios_system("wasm fixture.wasm");
        dispatch_semaphore_wait(prepared, DISPATCH_TIME_FOREVER);
        int status = 0;
        ios_full_waitpid(pid, &status, WNOHANG);
        dispatch_semaphore_signal(resume);
        ios_waitpid(pid);
        dprintf(STDERR_FILENO, "WASM command order after host drain: expected=1 actual=%d\n", observed);
        alarm(0);
        return observed == 1 ? 0 : 1;
    }
}
