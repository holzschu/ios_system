#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

static void host_handler(int number) { (void)number; }
static void timeout_handler(int number) { (void)number; _Exit(124); }
static const char *session = "signal-handler-check";

static void run_command(const char *command) {
    pid_t pid = ios_fork();
    ios_system(command);
    ios_waitpid(pid);
}

struct command_run {
    const char *session;
    char command[1200];
};

static void *run_shared_command(void *argument) {
    struct command_run *run = argument;
    @autoreleasepool {
        ios_switchSession(run->session);
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) _Exit(2);
        ios_setStreams(input, output, error);
        run_command(run->command);
    }
    return NULL;
}

static void wait_for_file(NSString *directory, NSString *name) {
    while (access([[directory stringByAppendingPathComponent:name] fileSystemRepresentation], F_OK)) usleep(1000);
}

static void mark_file(NSString *directory, NSString *name) {
    int fd = open([[directory stringByAppendingPathComponent:name] fileSystemRepresentation], O_WRONLY | O_CREAT, 0600);
    if (fd < 0) _Exit(2);
    close(fd);
}

static int shared_framework_signal(bool staggered) {
    char directory[1024];
    snprintf(directory, sizeof(directory), "%ssignal-shared-XXXXXX", [NSTemporaryDirectory() fileSystemRepresentation]);
    if (!mkdtemp(directory)) return 2;
    NSString *path = [NSString stringWithUTF8String:directory];
    struct command_run first = {"signal-first", ""}, second = {"signal-second", ""};
    snprintf(first.command, sizeof(first.command), "signal-handler --shared %s first", directory);
    snprintf(second.command, sizeof(second.command), "signal-handler --shared %s second", directory);
    signal(SIGINT, host_handler);
    signal(SIGWINCH, host_handler);
    pthread_t first_thread, second_thread;
    if (pthread_create(&first_thread, NULL, run_shared_command, &first)) return 2;
    wait_for_file(path, @"ready-first");
    if (staggered) {
        mark_file(path, @"install");
        wait_for_file(path, @"installed-first");
    }
    if (pthread_create(&second_thread, NULL, run_shared_command, &second)) return 2;
    wait_for_file(path, @"ready-second");
    mark_file(path, @"install");
    wait_for_file(path, @"installed-first");
    wait_for_file(path, @"installed-second");
    mark_file(path, @"finish-first");
    pthread_join(first_thread, NULL);
    raise(SIGWINCH);
    ios_switchSession(second.session);
    ios_kill();
    pthread_join(second_thread, NULL);
    NSData *received = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"received"]];
    struct sigaction actual = {0};
    sigaction(SIGINT, NULL, &actual);
    bool restoredInterrupt = actual.sa_handler == host_handler;
    sigaction(SIGWINCH, NULL, &actual);
    bool passed = [received isEqualToData:[@"WI" dataUsingEncoding:NSUTF8StringEncoding]] && restoredInterrupt && actual.sa_handler == host_handler;
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    if (!passed) {
        dprintf(STDERR_FILENO, "FAIL: shared framework lost signals or final host restore (staggered=%d received=%lu int=%d winch=%d)\n", staggered, (unsigned long)received.length, restoredInterrupt, actual.sa_handler == host_handler);
        return 1;
    }
    return 0;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        signal(SIGALRM, timeout_handler);
        alarm(20);
        initializeEnvironment();
        ios_switchSession(session);
        FILE *input = tmpfile(), *output = tmpfile(), *error = tmpfile();
        if (!input || !output || !error) return 2;
        ios_setStreams(input, output, error);
        joinMainThread = true;
        if (argc == 2 && strcmp(argv[1], "--staggered") == 0) {
            int result = shared_framework_signal(true);
            if (!result) dprintf(STDERR_FILENO, "PASS: staggered shared commands preserve signals and restore host handlers\n");
            alarm(0);
            return result;
        }
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
        // Both snapshots precede handler installation; first cleanup must leave the survivor alone.
        if (shared_framework_signal(false)) return 1;
        alarm(0);
        dprintf(STDERR_FILENO, "PASS: command handlers restored; masks, flags, unrelated handlers and shared-command signals preserved\n");
        return 0;
    }
}
