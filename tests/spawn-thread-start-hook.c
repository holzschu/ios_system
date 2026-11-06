// External OS scheduling boundary: complete an older public PID before one child thread starts.
#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>
#include <stdatomic.h>
#include <string.h>
extern void ios_releaseThreadId(int pid);
extern int ios_currentPid(void);
static _Atomic int completion_pid = -1;
static _Atomic int fail_creation;
static int failed_pid = -1;
void complete_pid_before_spawn_thread(int pid) { atomic_store(&completion_pid, pid); }
void fail_spawn_thread_after_completion(int pid) { atomic_store(&completion_pid, pid); atomic_store(&fail_creation, 1); }
int failed_spawn_pid(void) { return failed_pid; }
static int scheduled_create(pthread_t *thread, const pthread_attr_t *attributes, void *(*start)(void *), void *argument) {
    Dl_info image;
    if (dladdr((void *)start, &image) && strstr(image.dli_fname, "/ios_system.framework/ios_system")) {
        int pid = atomic_exchange(&completion_pid, -1);
        if (pid >= 0) {
            failed_pid = ios_currentPid();
            ios_releaseThreadId(pid);
            if (atomic_exchange(&fail_creation, 0)) return EAGAIN;
        }
    }
    return pthread_create(thread, attributes, start, argument);
}
__attribute__((used, section("__DATA,__interpose"))) static struct {
    const void *replacement;
    const void *original;
} hook = {(const void *)scheduled_create, (const void *)pthread_create};
