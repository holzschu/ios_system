#ifndef IOS_SPAWN_H
#define IOS_SPAWN_H
#include <sys/types.h>
#include <stddef.h>
#include <sys/resource.h>
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
/* Wait for an ios_posix_spawn PID; options is 0 or WNOHANG. Returns PID, 0 while
 * running, or -1 with errno. Status uses waitpid encoding (lost workers: exit 137).
 * Optional usage is the isolated worker's RUSAGE_SELF snapshot at command exit,
 * including process startup. availability is required when usage is requested;
 * zero means unavailable (including cancellation), never a measured zero. */
pid_t ios_wait4(pid_t, int *, int, struct rusage *, int *availability);
#endif
