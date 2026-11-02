// Test-only interposer: fail one native command's OS thread creation.
#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>
#include <stdatomic.h>
#include <string.h>

static _Atomic int armed;
static _Atomic int failures;
void fail_next_command_thread(void) { atomic_store(&armed, 1); }
int command_thread_failure_count(void) { return atomic_load(&failures); }

static int fail_create(pthread_t *thread, const pthread_attr_t *attributes, void *(*start)(void *), void *argument) {
    Dl_info image;
    if (dladdr((void *)start, &image) && strstr(image.dli_fname, "/ios_system.framework/ios_system") && atomic_exchange(&armed, 0)) {
        atomic_fetch_add(&failures, 1);
        return EAGAIN;
    }
    return pthread_create(thread, attributes, start, argument);
}
__attribute__((used, section("__DATA,__interpose"))) static struct {
    const void *replacement;
    const void *original;
} hook = {(const void *)fail_create, (const void *)pthread_create};
