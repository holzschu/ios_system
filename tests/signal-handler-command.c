#include <signal.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static int notification_fd = -1;
static void command_handler(int number) {
    if (notification_fd >= 0) {
        write(notification_fd, number == SIGINT ? "I" : "W", 1);
    }
}

static void mark(const char *directory, const char *name) {
    char path[1024];
    snprintf(path, sizeof(path), "%s/%s", directory, name);
    int fd = open(path, O_WRONLY | O_CREAT, 0600);
    if (fd < 0) _Exit(2);
    close(fd);
}

static void wait_for(const char *directory, const char *name) {
    char path[1024];
    snprintf(path, sizeof(path), "%s/%s", directory, name);
    while (access(path, F_OK)) usleep(1000);
}

int signal_handler_main(int argc, char **argv) {
    if (argc == 4 && strcmp(argv[1], "--shared") == 0) {
        const char *directory = argv[2];
        int first = strcmp(argv[3], "first") == 0;
        if (first) notification_fd = -1;
        mark(directory, first ? "ready-first" : "ready-second");
        wait_for(directory, "install");
        if (!first) {
            char path[1024];
            snprintf(path, sizeof(path), "%s/received", directory);
            notification_fd = open(path, O_WRONLY | O_CREAT, 0600);
            if (notification_fd < 0) return 2;
        }
        if (signal(SIGINT, command_handler) == SIG_ERR || signal(SIGWINCH, command_handler) == SIG_ERR) return 2;
        mark(directory, first ? "installed-first" : "installed-second");
        wait_for(directory, first ? "finish-first" : "finish-second");
        return 0;
    }
    if (argc < 2) return 0;
    return signal(atoi(argv[1]), command_handler) == SIG_ERR ? 1 : 0;
}
