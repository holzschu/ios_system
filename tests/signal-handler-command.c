#include <signal.h>
#include <stdlib.h>

static void command_handler(int number) { (void)number; }

int signal_handler_main(int argc, char **argv) {
    if (argc < 2) return 0;
    return signal(atoi(argv[1]), command_handler) == SIG_ERR ? 1 : 0;
}
