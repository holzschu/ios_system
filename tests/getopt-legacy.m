// Frameworks built before getopt became per-thread (ssh, bc, mandoc and others) import getopt, getopt_long,
// optind and optarg from ios_system and read the results from those variables. This file does not include
// ios_error.h, so it is such a caller: it must still see the option argument and the operand index.
#import <Foundation/Foundation.h>
#import "ios_system.h"
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int failures = 0;

// ios_system replaces stdout for the process, so write straight to descriptor 1.
static void say(const char *prefix, const char *text) {
    char line[256];
    int n = snprintf(line, sizeof(line), "%s: %s\n", prefix, text);
    write(1, line, n);
}

static void expect(int ok, const char *what) {
    say(ok ? "ok" : "FAIL", what);
    if (!ok) failures++;
}

// A prebuilt command: getopt_long from the exported symbols, results left in globals for the caller to read.
static int command_long = 0, command_operand_index = -1;
static char command_operand[32];
int legacyopt_main(int argc, char **argv) {
    static const struct option longopts[] = {{"long", no_argument, NULL, 'l'}, {NULL, 0, NULL, 0}};
    int c;
    command_long = 0;
    command_operand[0] = 0;
    while ((c = getopt_long(argc, argv, "l", longopts, NULL)) != -1)
        if (c == 'l') command_long = 1;
    command_operand_index = optind;
    if (optind < argc) strlcpy(command_operand, argv[optind], sizeof(command_operand));
    return 0;
}

int main(void) {
    // the same command three times through ios_system, with no reset in between: every run must start from argv[1]
    initializeEnvironment();
    ios_switchSession("getopt-legacy-probe");
    replaceCommand(@"legacyopt", @"legacyopt_main", false);
    for (int run = 1; run <= 3; run++) {
        char what[96];
        command_long = 0;
        command_operand_index = -1;
        command_operand[0] = 0;
        ios_system("legacyopt -l file");
        snprintf(what, sizeof(what), "run %d of a getopt_long command through ios_system sees -l and the operand", run);
        expect(command_long == 1 && command_operand_index == 2 && strcmp(command_operand, "file") == 0, what);
    }

    // getopt: ssh -p 22 host
    char *argv1[] = {"ssh", "-v", "-p", "22", "host", NULL};
    int c, port = -1, verbose = 0;
    optind = 1;
    while ((c = getopt(5, argv1, "vp:")) != -1) {
        if (c == 'p') port = optarg ? atoi(optarg) : -2;
        if (c == 'v') verbose = 1;
    }
    expect(verbose == 1, "getopt returns -v");
    expect(port == 22, "getopt leaves the argument of -p in optarg");
    expect(optind == 4, "getopt leaves optind on the first operand");

    // getopt_long: tool --count 3 --name=x file
    static const struct option longopts[] = {
        {"count", required_argument, NULL, 'c'},
        {"name", required_argument, NULL, 'n'},
        {NULL, 0, NULL, 0},
    };
    char *argv2[] = {"tool", "--count", "3", "--name=x", "file", NULL};
    int count = -1;
    char name[8] = "";
    optind = 1;
    while ((c = getopt_long(5, argv2, "c:n:", longopts, NULL)) != -1) {
        if (c == 'c') count = optarg ? atoi(optarg) : -2;
        if (c == 'n' && optarg) strlcpy(name, optarg, sizeof(name));
    }
    expect(count == 3, "getopt_long leaves the argument of --count in optarg");
    expect(strcmp(name, "x") == 0, "getopt_long leaves the argument of --name in optarg");
    expect(optind == 4, "getopt_long leaves optind on the first operand");

    // a second parse after the caller resets optind, as old code does
    char *argv3[] = {"ssh", "-p", "2222", "other", NULL};
    optind = 1;
    optreset = 1;
    port = -1;
    while ((c = getopt(4, argv3, "vp:")) != -1)
        if (c == 'p') port = optarg ? atoi(optarg) : -2;
    expect(port == 2222 && optind == 3, "a second parse after optind = 1 starts from the beginning");

    say("getopt-legacy", failures ? "FAIL" : "PASS");
    return failures ? 1 : 0;
}
