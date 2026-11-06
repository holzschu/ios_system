#include <dlfcn.h>
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdatomic.h>
#include <string.h>
#include <unistd.h>
extern int ios_currentPid(void);
extern pthread_t ios_getThreadId(int);
static _Atomic int stage = -1;
static _Atomic int ordered;
static dispatch_semaphore_t start_first;
static void *(*first_start)(void *);
static void *first_argument;
void arm_pipeline_thread_order(void) { start_first = dispatch_semaphore_create(0); atomic_store(&ordered, 0); atomic_store(&stage, 0); }
int pipeline_thread_ordered(void) { return atomic_load(&ordered); }
static void *delayed_start(void *unused) {
    dispatch_semaphore_wait(start_first, DISPATCH_TIME_FOREVER);
    return first_start(first_argument);
}
static int scheduled_create(pthread_t *thread, const pthread_attr_t *attributes, void *(*start)(void *), void *argument) {
    Dl_info image;
    if (atomic_load(&stage) >= 0 && dladdr((void *)start, &image) && strstr(image.dli_fname, "/ios_system.framework/ios_system")) {
        int current = atomic_fetch_add(&stage, 1);
        if (current == 0) {
            first_start = start; first_argument = argument;
            return pthread_create(thread, attributes, delayed_start, NULL);
        }
        if (current == 1) {
            int pid = ios_currentPid();
            dispatch_semaphore_signal(start_first);
            for (int n = 0; n < 1000 && ios_getThreadId(pid) == (pthread_t)-1; n++) usleep(1000);
            atomic_store(&ordered, ios_getThreadId(pid) != (pthread_t)-1);
            atomic_store(&stage, -1);
        }
    }
    return pthread_create(thread, attributes, start, argument);
}
__attribute__((used, section("__DATA,__interpose"))) static struct { const void *replacement; const void *original; } hook = {(const void *)scheduled_create, (const void *)pthread_create};
