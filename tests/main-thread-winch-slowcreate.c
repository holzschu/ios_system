// Interposes pthread_create for main-thread-winch.m: while delayCreate is set, the caller returns 100 ms after the
// new thread started, so a short command has ended before the caller goes on.
#include <pthread.h>
#include <stdatomic.h>
#include <unistd.h>

atomic_int delayCreate;

static int slowCreate(pthread_t *t, const pthread_attr_t *attr, void *(*fn)(void *), void *arg) {
    int result = pthread_create(t, attr, fn, arg);
    if (atomic_load(&delayCreate)) usleep(100 * 1000);
    return result;
}

__attribute__((used)) static struct { const void *replacement, *original; } interposers[]
    __attribute__((section("__DATA,__interpose"))) = { { (const void *)slowCreate, (const void *)pthread_create } };
