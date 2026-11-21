#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <dispatch/dispatch.h>
#include <dlfcn.h>
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <unistd.h>
static dispatch_semaphore_t drained, finished;
static volatile sig_atomic_t interrupted;
static _Atomic int returned, isolated;
int pipeline_signal_producer(int argc, char **argv) { fprintf(thread_stdout, "%d\n", getpid()); return 0; }
static void received(int sig) { interrupted = 1; }
static void completed(void *unused) { dispatch_semaphore_signal(finished); }
int pipeline_signal_consumer(int argc, char **argv) {
    struct sigaction action = {0}; action.sa_handler = received; sigemptyset(&action.sa_mask); sigaction(SIGINT, &action, NULL);
    sigset_t signals; sigemptyset(&signals); sigaddset(&signals, SIGINT); pthread_sigmask(SIG_UNBLOCK, &signals, NULL);
    pthread_cleanup_push(completed, NULL);
    char buffer[32] = {0}; ssize_t used = 0, count;
    while (used < sizeof(buffer) - 1 && (count = read(fileno(thread_stdin), buffer + used, sizeof(buffer) - 1 - used)) > 0) used += count;
    atomic_store(&isolated, used > 0 && atoi(buffer) != getpid());
    dispatch_semaphore_signal(drained);
    for (int n = 0; n < 500 && !interrupted; n++) usleep(10000);
    atomic_store(&returned, 1);
    pthread_cleanup_pop(1);
    return interrupted ? 0 : 1;
}
int main(void) {
    alarm(30); interrupted = 0; atomic_store(&returned, 0); atomic_store(&isolated, 0);
    drained = dispatch_semaphore_create(0); finished = dispatch_semaphore_create(0);
    void (*arm)(void) = dlsym(RTLD_DEFAULT, "arm_pipeline_thread_order");
    int (*ordered)(void) = dlsym(RTLD_DEFAULT, "pipeline_thread_ordered");
    if (!arm || !ordered) return 2;
    ios_setenv("ASHELL_WORKER_COMMANDS", "pipeline-signal-producer", 1);
    pid_t pid = ios_fork(); arm();
    int status = ios_system("pipeline-signal-producer | pipeline-signal-consumer");
    BOOL ready = dispatch_semaphore_wait(drained, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)) == 0;
    int killed = ready ? ios_killpid(pid, SIGINT) : -1;
    BOOL done = dispatch_semaphore_wait(finished, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)) == 0;
    BOOL passed = ordered() && atomic_load(&isolated) && ready && done && killed == 0 && interrupted && atomic_load(&returned);
    fprintf(thread_stdout, "shared pipeline PID SIGINT: %s (pid=%d status=%d ready=%d done=%d kill=%d signal=%d returned=%d isolated=%d ordered=%d)\n", passed ? "PASS" : "FAIL", pid, status, ready, done, killed, interrupted, atomic_load(&returned), atomic_load(&isolated), ordered());
    ios_unsetenv("ASHELL_WORKER_COMMANDS"); alarm(0); return passed ? 0 : 1;
}
