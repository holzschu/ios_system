// Run `emit | wasm` repeatedly via ios_system and count the app's open descriptors.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>

// Stand-in producer: a few KiB on stdout.
int emit_main(int argc, char **argv) {
    char block[1024];
    memset(block, 'x', sizeof(block));
    for (int i = 0; i < 4; i++) fwrite(block, 1, sizeof(block), thread_stdout);
    return 0;
}

// Stand-in consumer registered under the name "wasm": reads its pipe to EOF.
int wasm_main(int argc, char **argv) {
    char block[1024];
    while (fread(block, 1, sizeof(block), thread_stdin) > 0) {}
    return 0;
}

static int openDescriptors(void) {
    int count = 0;
    for (int fd = 0; fd < 1024; fd++) {
        if (fcntl(fd, F_GETFD) != -1) count++;
    }
    return count;
}

static void timedOut(int signal) { _Exit(124); }

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timedOut);
        alarm(60);
        initializeEnvironment();
        ios_switchSession("wasm-stdin-close-probe");
        ios_setStreams(stdin, stdout, stderr);
        replaceCommand(@"emit", @"emit_main", false);
        replaceCommand(@"wasm", @"wasm_main", false);
        joinMainThread = true;
        ios_system("emit | wasm");
        int before = openDescriptors();
        for (int i = 0; i < 50; i++) {
            ios_system("emit | wasm");
            if (ios_getCommandStatus() != 0) return 3;
        }
        int after = openDescriptors();
        BOOL passed = after <= before;
        fprintf(stderr, "descriptors after 50 pipelines: before=%d after=%d %s\n", before, after, passed ? "PASS" : "FAIL");
        alarm(0);
        return passed ? 0 : 1;
    }
}
