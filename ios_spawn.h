#ifndef IOS_SPAWN_H
#define IOS_SPAWN_H
#include <sys/types.h>
#include <stddef.h>
#include <sys/resource.h>
#include <stdio.h>
#ifdef __cplusplus
extern "C" {
#endif
/* Isolated worker processes inherit only stdin, stdout and stderr. */
typedef struct { int source, target; } ios_spawn_action;
typedef struct {
    ios_spawn_action *actions;
    size_t count;
    char *cwd;
} ios_posix_spawn_file_actions_t;
int ios_posix_spawn_file_actions_init(ios_posix_spawn_file_actions_t *);
int ios_posix_spawn_file_actions_destroy(ios_posix_spawn_file_actions_t *);
int ios_posix_spawn_file_actions_adddup2(ios_posix_spawn_file_actions_t *, int, int);
int ios_posix_spawn_file_actions_addclose(ios_posix_spawn_file_actions_t *, int);
int ios_posix_spawn_file_actions_addchdir_np(ios_posix_spawn_file_actions_t *, const char *);
int ios_posix_spawn(pid_t *, const char *, const ios_posix_spawn_file_actions_t *, const void *, char *const [], char *const []);
/* Like ios_posix_spawn, but route terminal Ctrl-C and Ctrl-D to this
 * interactive SFTP escape while it is active. */
int ios_spawn_sftp_escape(pid_t *, const char *, const ios_posix_spawn_file_actions_t *, const void *, char *const [], char *const []);
/* Stock transfer clients may lend their virtual terminal input to SSH without
 * replacing the child's protocol streams. A noninteractive caller lends nothing. */
int ios_posix_spawn_with_secret_input(pid_t *, const char *, const ios_posix_spawn_file_actions_t *, char *const [], char *const []);
/* The worker owns this stream; borrowers must not close it. */
void ios_setSecretInput(FILE *);
FILE *ios_getSecretInput(void);
/* Wait for an ios_posix_spawn PID; options is 0 or WNOHANG. Returns PID, 0 while
 * running, or -1 with errno. Status uses waitpid encoding (ios_killpid with SIGINT, SIGTERM, SIGKILL, SIGHUP or SIGQUIT: exit 128 + signal; worker transport failure: exit 125).
 * Optional usage is the isolated worker's RUSAGE_SELF snapshot at command exit,
 * including process startup. availability is required when usage is requested;
 * zero means unavailable (including cancellation), never a measured zero. */
pid_t ios_wait4(pid_t, int *, int, struct rusage *, int *availability);
#ifdef __cplusplus
}
#endif
#endif
