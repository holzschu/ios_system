#ifndef ASHELL_SSH_H
#define ASHELL_SSH_H
#include <stdio.h>
#include <wchar.h>
#include <wctype.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <pwd.h>
#include <errno.h>
#include <string.h>
#include <ios_error.h>
#include <ios_spawn.h>
#undef iswprint
#define waitpid ios_full_waitpid
#undef stdin
#undef stdout
#undef stderr
#define stdin thread_stdin
#define stdout thread_stdout
#define stderr thread_stderr
#undef STDIN_FILENO
#undef STDOUT_FILENO
#undef STDERR_FILENO
#define STDIN_FILENO fileno(thread_stdin)
#define STDOUT_FILENO fileno(thread_stdout)
#define STDERR_FILENO fileno(thread_stderr)
#define isatty ios_isatty

#define printf(...) fprintf(thread_stdout, __VA_ARGS__)
static inline int ashell_ssh_spawn(const char *path, char *const argv[], int input, int output, pid_t *pid) {
    ios_posix_spawn_file_actions_t actions;
    int error = ios_posix_spawn_file_actions_init(&actions);
    if (error) return error;
    error = ios_posix_spawn_file_actions_adddup2(&actions, input, 0);
    if (!error) error = ios_posix_spawn_file_actions_adddup2(&actions, output, 1);
    if (!error) error = ios_posix_spawn(pid, path, &actions, NULL, argv, environmentVariables(ios_currentPid()));
    ios_posix_spawn_file_actions_destroy(&actions);
    return error;
}
static inline struct passwd *ashell_ssh_getpwuid(uid_t uid) {
    static __thread struct passwd user;
    struct passwd *original = getpwuid(uid);
    if (original) user = *original;
    else {
        // Sandboxed Simulator processes may have no accessible passwd entry.
        if (uid != getuid()) return NULL;
        memset(&user, 0, sizeof(user));
        user.pw_name = getenv("USER");
        if (!user.pw_name || !*user.pw_name) user.pw_name = "mobile";
        user.pw_passwd = "*";
        user.pw_uid = uid;
        user.pw_gid = getgid();
        user.pw_gecos = "a-Shell";
        user.pw_shell = "dash";
    }
    const char *home = getenv("SSH_HOME");
    if (!home || !*home) home = getenv("HOME");
    if (home && *home) user.pw_dir = (char *)home;
    return &user;
}
#define getpwuid ashell_ssh_getpwuid
// A spawn adapter cannot duplicate an arbitrary instruction pointer.
static inline pid_t ashell_ssh_fork(void) { errno = ENOTSUP; return -1; }
#define fork ashell_ssh_fork
static inline int ashell_ssh_daemon(int nochdir, int noclose) {
    (void)nochdir; (void)noclose; errno = ENOTSUP; return -1;
}
#define daemon ashell_ssh_daemon
#endif
