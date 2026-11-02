#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <unistd.h>

int alias_output_main(int argc, char **argv) {
    if (argc != 3 || strcmp(argv[1], "alpha") || strcmp(argv[2], "beta")) return 99;
    fputs("OUT alpha beta\n", thread_stdout);
    fputs("ERR alpha beta\n", thread_stderr);
    return 7;
}

static void timedOut(int number) { _Exit(124); }

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc != 2) return 2;
        signal(SIGALRM, timedOut);
        alarm(10);
        NSString *directory = [NSString stringWithUTF8String:argv[1]];
        if (![[NSFileManager defaultManager] changeCurrentDirectoryPath:directory]) return 2;
        initializeEnvironment();
        ios_switchSession("alias-redirection");
        ios_setStreams(stdin, stdout, stderr);
        joinMainThread = true;
        replaceCommand(@"alias-output", @"alias_output_main", false);
        // Without the padding the stale bound was not exceeded before the fix; with it the abort reproduced in three runs out of three.
        NSString *alias = [NSString stringWithFormat:@"alias redirected 'alias-output alpha%@beta'",
                           [@"" stringByPaddingToLength:2048 withString:@" " startingAtIndex:0]];
        if (ios_system(alias.UTF8String)) return 2;
        unlink("stdout.txt");
        unlink("stderr.txt");
        int status = ios_system("redirected > stdout.txt 2> stderr.txt");
        NSString *output = [NSString stringWithContentsOfFile:@"stdout.txt" encoding:NSUTF8StringEncoding error:nil];
        NSString *error = [NSString stringWithContentsOfFile:@"stderr.txt" encoding:NSUTF8StringEncoding error:nil];
        BOOL passed = status == 7 && [output isEqualToString:@"OUT alpha beta\n"] && [error isEqualToString:@"ERR alpha beta\n"];
        dprintf(STDERR_FILENO, "redirected alias: status=%d stdout=%s stderr=%s %s\n", status,
                [output isEqualToString:@"OUT alpha beta\n"] ? "exact" : "FAIL",
                [error isEqualToString:@"ERR alpha beta\n"] ? "exact" : "FAIL", passed ? "PASS" : "FAIL");
        alarm(0);
        return passed ? 0 : 1;
    }
}
