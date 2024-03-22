//
//  ios_system.m
//
//  Created by Nicolas Holzschuch on 17/11/2017.
//  Copyright © 2017 N. Holzschuch. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "ios_system.h"

// ios_system(cmd): Executes the command in "cmd". The goal is to be a drop-in replacement for system(), as much as possible.
// We assume cmd is the command. If vim has prepared '/bin/sh -c "(command -arguments) < inputfile > outputfile",
// it is easier to remove the "/bin/sh -c" part before calling ios_system than inside ios_system.
// See example in (iVim) os_unix.c
//
// ios_executable(cmd): returns true if the command is one of the commands defined in ios_system, and can be executed.
// This is because mch_can_exe (called by executable()) checks for the existence of binaries with the same name in the
// path. Our commands don't exist in the path.
//
// ios_popen(cmd, type): returns a FILE*, executes cmd, and thread_output into input of cmd (if type=="w") or
// the reverse (if type == "r").

#include <pthread.h>
#include <sys/stat.h>
#include <libgen.h> // for basename()
#include <dlfcn.h>  // for dlopen()/dlsym()/dlclose()
#include <glob.h>   // for wildcard expansion
// Sideloading: when you compile yourself, as opposed to uploading on the app store
// If true, all commands are enabled + debug messages if dylib not found.
// If false, you get a smaller set, but compliance with AppStore rules.
// *Must* be false in the main branch releases.
// Commands that can be enabled only if sideLoading: chgrp, chown, df, id, w.
bool sideLoading = false; 
// Should the main thread be joined (which means it takes priority over other tasks)? 
// Default value is true, which makes sense for shell-like applications.
// Should be set to false if significant user interaction is carried by the app and 
// the app takes responsibility for waiting for the command to terminate. 
bool joinMainThread = true;
static NSString* ios_bookmarkDictionaryName = @"bookmarkNames";
// Include file for getrlimit/setrlimit:
#include <sys/resource.h>
static struct rlimit limitFilesOpen;
extern void display_alert(NSString* title, NSString* message);


extern __thread int    __db_getopt_reset;
__thread FILE* thread_stdin;
__thread FILE* thread_stdout;
__thread FILE* thread_stderr;
__thread void* thread_context;

FILE* ios_stdin(void) {
    return thread_stdin;
}

FILE* ios_stdout(void) {
    return thread_stdout;
}

FILE* ios_stderr(void) {
    return thread_stderr;
}

void* ios_context(void) {
    return thread_context;
}

// Parameters for each session. We can have multiple sessions running in parallel.
typedef struct _sessionParameters {
    bool isMainThread;   // are we on the first command?
    char currentDir[MAXPATHLEN];
    char previousDirectory[MAXPATHLEN];
    char localMiniRoot[MAXPATHLEN];
    pthread_t current_command_root_thread; // thread ID of first command
    pthread_t lastThreadId; // thread ID of last command.
    pthread_t mainThreadId; // thread ID of parent command, if any (e.g. vim, which starts "sh -c cd dir && flake8 file")
    FILE* stdin;
    FILE* stdout;
    FILE* stderr;
    FILE* tty;
    void* context;
    int global_errno;
    int numCommandsAllocated;
    int numCommand;
    char** commandName;
    char columns[5];
    char lines[5];
    bool activePager;
} sessionParameters;

static void initSessionParameters(sessionParameters* sp) {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    sp->isMainThread = TRUE;
    sp->current_command_root_thread = 0;
    sp->lastThreadId = 0;
    sp->mainThreadId = 0;
    NSString* currentDirectory = [fileManager currentDirectoryPath];
    strcpy(sp->currentDir, [currentDirectory UTF8String]);
    strcpy(sp->previousDirectory, [currentDirectory UTF8String]);
    sp->localMiniRoot[0] = 0;
    sp->global_errno = 0;
    sp->stdin = stdin;
    sp->stdout = stdout;
    sp->stderr = stderr;
    sp->tty = stdin;
    sp->context = nil;
    sp->numCommandsAllocated = 10; // 10 slots available to store commands, will realloc if more needed.
    sp->commandName = malloc(sizeof(char*) * sp->numCommandsAllocated);
    for (int i = 0; i < sp->numCommandsAllocated; i++) {
        sp->commandName[i] = malloc(sizeof(char) * NAME_MAX);
    }
    sp->commandName[0][0] = 0;
    sp->numCommand = 0;
    strcpy(sp->columns, "80");
    strcpy(sp->lines, "80");
    sp->activePager = FALSE;
}

void ios_setBookmarkDictionaryName(NSString* name) {
    ios_bookmarkDictionaryName = name;
}

const char* ios_getBookmarkedVersion(const char* p) {
    // p is a directory. Get the bookmarked version to make it shorter:
    NSString* pathString = [NSString stringWithUTF8String:p];
    NSString* privatePrefix = @"/private";
    if ([pathString hasPrefix:privatePrefix]) {
        pathString = [pathString substringFromIndex:[privatePrefix length]];
    }
    NSString *homePath;
    homePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByDeletingLastPathComponent];
    if ([homePath hasPrefix:privatePrefix]) {
        homePath = [homePath substringFromIndex:[privatePrefix length]];
    }
    // NSLog(@"ios_getBookmarkedVersion: %s %s", homePath.UTF8String, pathString.UTF8String);
    if ([pathString hasPrefix:homePath]) {
        pathString = [pathString stringByReplacingOccurrencesOfString:homePath withString:@"~"];
        return pathString.UTF8String;
    }
    if (ios_bookmarkDictionaryName == nil) {
        return p;
    }
    NSDictionary *tildeExpansionDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ios_bookmarkDictionaryName];
    if (tildeExpansionDictionary == nil) {
        return p;
    }
    NSString* foundString = @"";
    for (NSString* bookmark in tildeExpansionDictionary) {
        NSString* bookmarkPath = tildeExpansionDictionary[bookmark];
        if ([bookmarkPath hasPrefix:privatePrefix]) {
            bookmarkPath = [bookmarkPath substringFromIndex:[privatePrefix length]];
        }
        if ([pathString hasPrefix:bookmarkPath]) {
            NSString* testString = [pathString stringByReplacingOccurrencesOfString:bookmarkPath withString:[@"~" stringByAppendingString: bookmark]];
            if ((foundString.length == 0) || (testString.length < foundString.length))
                foundString = testString;
        }
    }
    if (foundString.length > 0)
        return foundString.UTF8String;
    return p;
}

static NSMutableDictionary* sessionList;
static NSMutableDictionary* aliasDictionary;

// pointer to sessionParameters. thread-local variable so the entire system is thread-safe.
// The sessionParameters pointer is shared by all threads in the same session.
static __thread sessionParameters* currentSession;
// Python3 multiple interpreters:
// limit to 6 = 1 kernel, 4 notebooks, one extra.
static const int MaxPythonInterpreters = 6; // const so we can allocate an array
int numPythonInterpreters = MaxPythonInterpreters; // Apps can overwrite this
static bool PythonIsRunning[MaxPythonInterpreters];
static int currentPythonInterpreter = 0;
static bool showPythonInterpreterAlert = true;
// Same with perl:
static const int MaxPerlInterpreters = 4; // const so we can allocate an array
// cpan starts perl Makefile.PL, which starts perl -e print Version, so at least 3.
int numPerlInterpreters = MaxPerlInterpreters; // Apps can overwrite this
static bool PerlIsRunning[MaxPerlInterpreters];
static int currentPerlInterpreter = 0;
// same with TeX, with a twist:
static const int MaxTeXInterpreters = 2; // const so we can allocate an array
// (La)TeX can start another (La)TeX command for TikZ
int numTeXInterpreters = MaxTeXInterpreters; // Apps can overwrite this
static bool TeXIsRunning[MaxTeXInterpreters];
static int currentTeXInterpreter = 0;
NSArray *TeXcommands = nil; // initialized later
// Multiple dash:
// limit to 6 (for now)
static const int MaxDashCommands = 6; // const so we can allocate an array
int numDashCommands = MaxDashCommands; // Apps can overwrite this
static bool dashIsRunning[MaxDashCommands];
static int currentDashCommand = 0;
// multiple ssh (limit to 2):
static const int MaxSshCommands = 2; // const so we can allocate an array
int numSshCommands = MaxSshCommands; // Apps can overwrite this
static bool sshIsRunning[MaxSshCommands];
static int currentSshCommand = 0;


// pointers for sh sessions:
char* sh_session = "sh_session";

// replace system-provided exit() by our own:
void ios_exit(int n) {
    if (currentSession != NULL) {
        currentSession->global_errno = n;
    }
    pthread_exit(NULL);
}

void set_session_errno(int n) {
    if (currentSession != NULL) {
        currentSession->global_errno = n;
    }
}

// Replace standard abort and exit functions with ours:
// We also do this using #define, but this is for the unmodified code.
void abort(void) {
    ios_exit(1);
}
void exit(int n) {
    ios_exit(n);
}
void _exit(int n) {
    ios_exit(n);
}
//

void ios_signal(int signal) {
    // This function is probably obsolete now. If we keep using it, remember that currentSession is not necessarily the currentSession
    // (if currentSession started sh_session, then we might be sending the signal to the wrong session).
    // Signals the threads of the current session:
    if (currentSession != NULL) {
        if (currentSession->current_command_root_thread != NULL) {
            pthread_kill(currentSession->current_command_root_thread, signal);
        }
        if (currentSession->lastThreadId != NULL) {
            pthread_kill(currentSession->lastThreadId, signal);
        }
        if (currentSession->mainThreadId != NULL) {
            pthread_kill(currentSession->mainThreadId, signal);
        }
    }
}

NSString *ios_getLogicalPWD(const void* sessionId) {
    id sessionKey = @((NSUInteger)sessionId);
    if (sessionList == nil) {
        return nil;
    }
    sessionParameters *session = (sessionParameters*)[[sessionList objectForKey: sessionKey] pointerValue];
    if (session == nil) {
        return nil;
    }
    return @(session->currentDir);
}

#undef getenv
void ios_setWindowSize(int width, int height, const void* sessionId) {
    // You can set the window size for a session that is not currently running (e.g. because "sh_session" is running).
    // So we set it without calling ios_switchSession:
    sessionParameters* resizedSession;

    id sessionKey = @((NSUInteger)sessionId);
    if (sessionList == nil) {
        return;
    }
    resizedSession = (sessionParameters*)[[sessionList objectForKey: sessionKey] pointerValue];
    if (resizedSession == nil) {
        return;
    }

    sprintf(resizedSession->columns, "%d", MIN(width, 9999));
    sprintf(resizedSession->lines, "%d", MIN(height, 9999));
    // Also send SIGWINCH to the main thread of resizedSession:
    if (resizedSession->current_command_root_thread != NULL) {
        pthread_kill(resizedSession->current_command_root_thread, SIGWINCH);
    }
    if (resizedSession->lastThreadId != NULL) {
        pthread_kill(resizedSession->lastThreadId, SIGWINCH);
    }
    if (resizedSession->mainThreadId != NULL) {
        pthread_kill(resizedSession->mainThreadId, SIGWINCH);
    }
}

extern char* libc_getenv(const char* variableName);
char * ios_getenv(const char *name) {
    // intercept calls to getenv("COLUMNS") / getenv("LINES")
    if (strcmp(name, "COLUMNS") == 0) {
        return currentSession->columns;
    }
    if (strcmp(name, "LINES") == 0) {
        return currentSession->lines;
    }
    if (strcmp(name, "ROWS") == 0) {
        return currentSession->lines;
    }
    if (strcmp(name, "PWD") == 0) {
        return currentSession->currentDir;
    }
    return libc_getenv(name);
}

void ios_IsMainThread(bool value) {
    currentSession->isMainThread = value;
}

int ios_getCommandStatus(void) {
    if (currentSession != NULL) return currentSession->global_errno;
    else return 0;
}

extern const char* ios_progname(void) {
    if (currentSession != NULL) {
        if (currentSession->numCommand <= 0)
            return currentSession->commandName[0];
        else
            return currentSession->commandName[currentSession->numCommand - 1];
    }
    else return getprogname();
}

const char* ios_expandtilde(const char *login) {
    // expand "~something" with the content of userPreference dictionary (to be set by each app)
    // About the same behaviour as:
    // struct passwd *pw = getpwnam(name);
    // return pw ? pw->pw_dir : 0;
    NSDictionary *tildeExpansionDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ios_bookmarkDictionaryName];
    if (tildeExpansionDictionary != nil) {
        NSString* name = [NSString stringWithUTF8String:login];
        NSString* expandedPath = tildeExpansionDictionary[name];
        if (expandedPath != nil) {
            return [expandedPath UTF8String];
        }
    }
    return NULL;
}

typedef struct _functionParameters {
    int argc;
    char** argv;
    char** argv_ref;
    int (*function)(int ac, char** av);
    FILE *stdin, *stdout, *stderr;
    void* context;
    void* dlHandle;
    bool isPipeIn;
    bool isPipeOut;
    bool isPipeErr;
    bool backgroundCommand;
    int  numInterpreter;
    bool storeRootThread;
    sessionParameters* session;
} functionParameters;

extern pthread_mutex_t pid_mtx;
extern _Atomic(int) cleanup_counter;
extern void ios_releaseBackgroundThread(pthread_t thread);
extern void startedPreparingWebAssemblyCommand(void);

static void cleanup_function(void* parameters) {
    // This function is called when pthread_exit() or ios_kill() is called
    pthread_t current_thread = pthread_self();
    functionParameters *p = (functionParameters *) parameters;
    bool backgroundCommand = p->backgroundCommand;
    char* commandName = p->argv[0];
    char* currentSessionCommandName = NULL;
    bool toNonInteractive = false;
    
    if (currentSession->numCommand <= 0)
        currentSessionCommandName = currentSession->commandName[0];
    else
        currentSessionCommandName = currentSession->commandName[currentSession->numCommand - 1];
    NSLog(@"cleanup_function: %s thread_id %x pid: %d stdin %d stdout %d stderr %d isPipeOut %d", commandName, current_thread, ios_currentPid(), fileno(p->stdin), fileno(p->stdout), fileno(p->stderr), p->isPipeOut);
    NSLog(@"currentSession->commandName: %s root_thread: %x", currentSessionCommandName, currentSession->current_command_root_thread);
    NSLog(@"Num commands stored: %d", currentSession->numCommand);
    if ((strcmp(commandName, "less") == 0) || (strcmp(commandName, "more") == 0)) {
        if ((strlen(currentSessionCommandName) > 0)
            && (strcmp(currentSessionCommandName, "less") != 0)
            && (strcmp(currentSessionCommandName, "more") != 0)) {
            // Command was "root_command | sthg | less". We need to kill root command.
            // If less itself started another command, then currentSession->commandName is "".
            // Unless less / more was started as a pager, in which case don't kill root command (e.g. for man and ipython help).
            pthread_kill(currentSession->current_command_root_thread, SIGINT);
            while (fgetc(thread_stdin) != EOF) { } // flush input, otherwise previous command gets blocked.
        } else {
            // but for python or ipython help(), flush the content of stdin:
            if ((currentSession->numCommand > 1) &&
                ((strncmp(currentSession->commandName[currentSession->numCommand - 2], "ipython", 7) == 0) ||
                 (strncmp(currentSession->commandName[currentSession->numCommand - 2], "isympy", 6) == 0) ||
                 (strncmp(currentSession->commandName[currentSession->numCommand - 2], "python", 6) == 0))) {
                while (fgetc(thread_stdin) != EOF) { } // flush input to help() command
                if (strncmp(currentSession->commandName[currentSession->numCommand - 2], "python", 6) == 0) {
                    toNonInteractive = true;
                }
            }
        }
        currentSession->activePager = FALSE;
    }
    // If the command was started as a pipe, we wait for the first command to finish sending data
    // There is an exception for ssh, which can be started by scp or sftp. They will wait for it.
    if ((!joinMainThread) && p->isPipeOut && (strcmp(commandName, "ssh") != 0)) {
        if (currentSession->current_command_root_thread != 0) {
            if (currentSession->current_command_root_thread != current_thread) {
                NSLog(@"Thread %x is waiting for root_thread of currentSession: %x \n", current_thread, currentSession->current_command_root_thread);
                while ((currentSession->current_command_root_thread != 0) && (currentSession->current_command_root_thread != current_thread)) {
                    fflush(thread_stdout);
                    fflush(thread_stderr);
                }
                NSLog(@"Thread %x is done waiting for root_thread of currentSession: %x \n", current_thread, currentSession->current_command_root_thread);
            } else {
                NSLog(@"Terminating root_thread of currentSession %x \n", current_thread);
                currentSession->current_command_root_thread = 0;
            }
        }
    }
    fcntl(fileno(thread_stdin), F_SETNOSIGPIPE);
    fcntl(fileno(thread_stdout), F_SETNOSIGPIPE);
    fcntl(fileno(thread_stderr), F_SETNOSIGPIPE);
    fflush(thread_stdin);
    fflush(thread_stdout);
    fflush(thread_stderr);
    // release parameters:
    NSLog(@"Terminating command: %s thread_id %x stdin %d stdout %d stderr %d isPipeOut %d", commandName, current_thread, fileno(p->stdin), fileno(p->stdout), fileno(p->stderr), p->isPipeOut);
    // Specific to run multiple python3 interpreters:
    NSString* commandNameString = [NSString stringWithCString: commandName encoding:NSUTF8StringEncoding];
    // Can we close stdin too?
    bool mustCloseStdin = fileno(p->stdin) != fileno(stdin);
    if (strncmp(commandName, "python", 6) == 0) {
        // It could be one of the multiple python3 interpreters
        PythonIsRunning[p->numInterpreter] = false;
        mustCloseStdin = false;
    }
    // Same with multiple perl or TeX interpreters:
    else if (strncmp(commandName, "perl", 4) == 0) {
        NSLog(@"Ending a Perl interpreter: %d", p->numInterpreter);
        PerlIsRunning[p->numInterpreter] = false;
    } else if ([TeXcommands containsObject: commandNameString]) {
        NSLog(@"Ending a TeX command: %d", p->numInterpreter);
        TeXIsRunning[p->numInterpreter] = false;
    } else if (strcmp(commandName, "dash") == 0) {
        NSLog(@"Ending a dash command: %d", p->numInterpreter);
        dashIsRunning[p->numInterpreter] = false;
    } else if (strcmp(commandName, "ssh") == 0) {
        NSLog(@"Ending a ssh command: %d", p->numInterpreter);
        sshIsRunning[p->numInterpreter] = false;
    }
    if (currentSession->numCommand > 0)
        currentSession->numCommand -= 1;
    else
        currentSession->commandName[0][0] = 0;
    // if (strcmp(currentSession->commandName, commandName) == 0) {
    //     currentSession->commandName[0] = 0;
    // }
    bool isSh = strcmp(p->argv[0], "sh") == 0;
    bool isWasm = strcmp(p->argv[0], "wasm") == 0;
    for (int i = 0; i < p->argc; i++) free(p->argv_ref[i]);
    free(p->argv_ref);
    free(p->argv);
    bool isLastThread = (currentSession->lastThreadId == current_thread);
    bool mustCloseStderr = (fileno(p->stderr) != fileno(stderr)) && (fileno(p->stderr) != fileno(p->stdout))  && (fileno(p->stdout) != fileno(p->stdin));
    if (!isSh) {
        mustCloseStderr &= p->isPipeErr;
        if (currentSession != nil) {
            mustCloseStderr &= fileno(p->stderr) != fileno(currentSession->stderr);
            mustCloseStderr &= fileno(p->stderr) != fileno(currentSession->stdout);
        }
    }
    // Some programs stop waiting as soon as stdout/stderr close (which makes sense)
    // This fclose does close the fileno, but I find it re-opened later.
    cleanup_counter++;
    while (pthread_mutex_trylock(&pid_mtx) != 0) { } // Someone else has the lock, so we wait.
    pthread_mutex_unlock(&pid_mtx);
    if (mustCloseStderr) {
        NSLog(@"Closing stderr (mustCloseStderr): %d \n", fileno(p->stderr));
        int res = fclose(p->stderr);
    }
    // In some cases, we find that stdout is equal to stdin after executing the command. We should not close stdin!
    bool mustCloseStdout = (fileno(p->stdout) != fileno(stdout)) && (fileno(p->stdout) != fileno(p->stdin));
    if (!isSh) {
        mustCloseStdout &= p->isPipeOut;
        if (currentSession != nil) {
            mustCloseStdout &= fileno(p->stdout) != fileno(currentSession->stdout);
        }
    }
    if (mustCloseStdout) {
        NSLog(@"Closing stdout (mustCloseStdout): %d \n", fileno(p->stdout));
        int res = fclose(p->stdout);
    }
    if (!isSh) {
        mustCloseStdin &= p->isPipeIn;
        if (currentSession != nil) {
            mustCloseStdin &= fileno(p->stdin) != fileno(currentSession->stdin);
        }
        // we cannot close stdin for wasm commands:
        mustCloseStdin &= !isWasm;
        // commands started by Python: Python will close stdin (Lua and Perl? not broken, AFAIK)
        if ((currentSession->numCommand > 0) && (strncmp(currentSession->commandName[currentSession->numCommand - 1], "python", 6) == 0)) {
            // NSLog(@"Command started by Python, not closing stdin: %d \n", fileno(p->stdin));
            mustCloseStdin &= false;
        }
    }
    if (mustCloseStdin) {
        NSLog(@"Closing stdin (mustCloseStdin): %d \n", fileno(p->stdin));
        int res = fclose(p->stdin);
    }
    if ((p->dlHandle != RTLD_SELF) && (p->dlHandle != RTLD_MAIN_ONLY)
        && (p->dlHandle != RTLD_DEFAULT) && (p->dlHandle != RTLD_NEXT))
        dlclose(p->dlHandle);
    free(parameters); // This was malloc'ed in ios_system
    if (isLastThread) {
        NSLog(@"Terminating lastthread of currentSession %x lastThreadId %x pid: %d\n", current_thread, currentSession->lastThreadId, ios_currentPid());
        currentSession->lastThreadId = 0;
    } else {
        NSLog(@"Current thread %x lastthread %x pid: %d\n", pthread_self(), currentSession->lastThreadId, ios_currentPid());
    }
    if (backgroundCommand) {
        // If it's a background command, call ios_releaseBackgroundThread:
        // NSLog(@"Releasing a backgroundCommand\n");
        ios_releaseBackgroundThread(current_thread);
    } else {
        if (toNonInteractive) {
            ios_stopInteractive();
        }
        ios_releaseThread(current_thread);
    }
    if (currentSession->current_command_root_thread == current_thread) {
        currentSession->current_command_root_thread = 0;
    }
    if (currentSession->mainThreadId == current_thread) {
        currentSession->mainThreadId = 0;
    }
    cleanup_counter--;
    NSLog(@"returning from cleanup_function\n");
}

// Avoir calling crash_handler several times:
static __thread bool crash_handler_called = false;
void crash_handler(int sig) {
    if (thread_stderr == NULL) thread_stderr = stderr;
    if (!crash_handler_called) {
        crash_handler_called = true;
        if (sig == SIGSEGV) {
            fputs("segmentation fault\n", thread_stderr);
        } else if (sig == SIGBUS) {
            fputs("bus error\n", thread_stderr);
        } else if (sig == SIGPIPE) {
            fputs("pipe error\n", thread_stderr);
            return;
        }
        ios_exit(1);
    }
}

static void* run_function(void* parameters) {
    functionParameters *p = (functionParameters *) parameters;
    NSLog(@"Storing thread_id: %x pid: %d isPipeOut: %x isPipeErr: %x stdin %d stdout %d stderr %d command= %s\n", pthread_self(), ios_currentPid(), p->isPipeOut, p->isPipeErr,
          (p->stdin == nil) ? -1 : fileno(p->stdin),
          (p->stdout == nil) ? -1 : fileno(p->stdout),
          (p->stderr == nil) ? -1 : fileno(p->stderr), p->argv[0]);
    ios_storeThreadId(pthread_self());
    if (p->storeRootThread && (p->session != NULL)) {
        NSLog(@"Storing thread_id: %x as root_thread\n", pthread_self());
        p->session->current_command_root_thread = pthread_self();
    }
    // NSLog(@"Starting command: %s thread_id %x", p->argv[0], pthread_self());
    // re-initialize for getopt:
    // TODO: move to __thread variable for optind too
    optind = 1;
    opterr = 1;
    optreset = 1;
    __db_getopt_reset = 1;
    thread_stdin  = p->stdin;
    thread_stdout = p->stdout;
    thread_stderr = p->stderr;
    thread_context = p->context;
    currentSession = p->session;
    if ((strcmp(p->argv[0], "less") == 0) || (strcmp(p->argv[0], "more") == 0)) {
        if (currentSession != nil) currentSession->activePager = TRUE;
    }

    signal(SIGSEGV, crash_handler);
    signal(SIGBUS, crash_handler);
    signal(SIGPIPE, crash_handler);

    // Because some commands change argv, keep a local copy for release.
    p->argv_ref = (char **)malloc(sizeof(char*) * (p->argc + 1));
    for (int i = 0; i < p->argc; i++) p->argv_ref[i] = p->argv[i];
    pthread_cleanup_push(cleanup_function, parameters);
    @try
    {
        int retval = p->function(p->argc, p->argv);
        if (currentSession != nil) currentSession->global_errno = retval;
    }
    @catch (NSException *exception)
    {
      // Print exception information.
      NSLog( @"NSException caught" );
      NSLog( @"Name: %@", exception.name);
      NSLog( @"Reason: %@", exception.reason );
        fprintf(thread_stderr, "Command %s was interrupted because it triggered a system exception: %s: %s\n", p->argv[0], exception.name.UTF8String, exception.reason.UTF8String);
      return NULL;
    }
    @finally
    {
      // Cleanup, in both success and fail cases
        pthread_cleanup_pop(1);
        return NULL;
    }
}

static NSString* miniRoot = nil; // limit operations to below a certain directory (~, usually).
static NSArray<NSString*> *allowedPaths = nil;
static NSDictionary *commandList = nil;
NSArray *backgroundCommandList = nil;
// do recompute directoriesInPath only if $PATH has changed
static NSString* fullCommandPath = @"";
static NSArray *directoriesInPath;

void initializeEnvironment(void) {
    // setup a few useful environment variables
    // Initialize paths for application files, including history.txt and keys
    NSString *docsPath;
    if (miniRoot == nil) docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    else docsPath = miniRoot;
    
    // Where the executables are stored: $PATH + ~/Library/bin + ~/Documents/bin
    // Add content of old PATH to this. PATH *is* defined in iOS, surprising as it may be.
    // I'm not going to erase it, so we just add ourselves.
    // Sometimes, we go through main several times, so make sure we only append to PATH once
    NSString* checkingPath = [NSString stringWithCString:getenv("PATH") encoding:NSUTF8StringEncoding];
    if (! [fullCommandPath isEqualToString:checkingPath]) {
        fullCommandPath = checkingPath;
    }
    if (![fullCommandPath containsString:@"Documents/bin"]) {
        NSString *binPath = [docsPath stringByAppendingPathComponent:@"bin"];
        fullCommandPath = [[binPath stringByAppendingString:@":"] stringByAppendingString:fullCommandPath];
        setenv("PATH", fullCommandPath.UTF8String, 1); // 1 = override existing value
    }
    setenv("APPDIR", [[NSBundle mainBundle] resourcePath].UTF8String, 1);
    setenv("PATH_LOCALE", docsPath.UTF8String, 0); // CURL config in ~/Documents/ or [Cloud Drive]/

    setenv("TERM", "xterm", 1); // 1 = override existing value
    setenv("TMPDIR", NSTemporaryDirectory().UTF8String, 0); // tmp directory
    setenv("CLICOLOR", "1", 1);
    setenv("LSCOLORS", "ExFxBxDxCxegedabagacad", 0); // colors for ls on black background
    
    // We can't write in $HOME so we need to set the position of config files:
    setenv("SSH_HOME", docsPath.UTF8String, 0);  // SSH keys in ~/Documents/.ssh/ or [Cloud Drive]/.ssh
    setenv("DIG_HOME", docsPath.UTF8String, 0);  // .digrc is in ~/Documents/.digrc or [Cloud Drive]/.digrc
    setenv("CURL_HOME", docsPath.UTF8String, 0); // CURL config in ~/Documents/ or [Cloud Drive]/
    setenv("CURLOPT_SSH_KNOWNHOSTS", [docsPath stringByAppendingPathComponent:@".ssh/known_hosts"].UTF8String, 0);
    setenv("SSL_CERT_FILE", [docsPath stringByAppendingPathComponent:@"cacert.pem"].UTF8String, 0); // SLL cacert.pem in ~/Documents/cacert.pem or [Cloud Drive]/cacert.pem
    // iOS already defines "HOME" as the home dir of the application
    for (int i = 0; i < MaxPythonInterpreters; i++) PythonIsRunning[i] = false;
    for (int i = 0; i < MaxPerlInterpreters; i++) PerlIsRunning[i] = false;
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    // environment variables for Python:
    setenv("PYTHONHOME", libPath.UTF8String, 0);  // Python files are in ~/Library/lib/python[23].x/
    // XDG setup directories (~/Library/Caches, ~/Library/Preferences):
    setenv("XDG_CACHE_HOME", [libPath stringByAppendingPathComponent:@"Caches"].UTF8String, 0);
    setenv("XDG_CONFIG_HOME", [libPath stringByAppendingPathComponent:@"Preferences"].UTF8String, 0);
    setenv("XDG_DATA_HOME", libPath.UTF8String, 0);
    // if we use Python, we define a few more environment variables:
    setenv("PYTHONEXECUTABLE", "python3", 0);  // Python executable name for python3
    setenv("PYZMQ_BACKEND", "cffi", 0);
    // Configuration files are in $HOME (and hidden)
    setenv("JUPYTER_CONFIG_DIR", [docsPath stringByAppendingPathComponent:@".jupyter"].UTF8String, 0);
    setenv("IPYTHONDIR", [docsPath stringByAppendingPathComponent:@".ipython"].UTF8String, 0);
    setenv("MPLCONFIGDIR", [docsPath stringByAppendingPathComponent:@".config/matplotlib"].UTF8String, 0);
    // hg config file in ~/Documents/.hgrc
    setenv("HGRCPATH", [docsPath stringByAppendingPathComponent:@".hgrc"].UTF8String, 0);
    if (![fullCommandPath containsString:@"Library/bin"]) {
        NSString *binPath = [libPath stringByAppendingPathComponent:@"bin"];
        fullCommandPath = [[binPath stringByAppendingString:@":"] stringByAppendingString:fullCommandPath];
    }
    if (!sideLoading) {
        // If we're not sideloading, executeables will also be in the Application directory
        NSString *mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString *mainBundleLibPath = [mainBundlePath stringByAppendingPathComponent:@"Library"];
        // if we're not sideloading, all "executable" files are in the AppDir:
        // $APPDIR/Library/bin3
        NSString *binPath = [mainBundleLibPath stringByAppendingPathComponent:@"bin3"];
        fullCommandPath = [[binPath stringByAppendingString:@":"] stringByAppendingString:fullCommandPath];
        // $APPDIR/Library/bin
        binPath = [mainBundleLibPath stringByAppendingPathComponent:@"bin"];
        fullCommandPath = [[binPath stringByAppendingString:@":"] stringByAppendingString:fullCommandPath];
        // $APPDIR/bin
        binPath = [mainBundlePath stringByAppendingPathComponent:@"bin"];
        fullCommandPath = [[binPath stringByAppendingString:@":"] stringByAppendingString:fullCommandPath];
    }
    directoriesInPath = [fullCommandPath componentsSeparatedByString:@":"];
    setenv("PATH", fullCommandPath.UTF8String, 1); // 1 = override existing value
    // Store the maximum number of file descriptors allowed:
    getrlimit(RLIMIT_NOFILE, &limitFilesOpen);
    // Initialize the array with the name of TeX commands (this might be too many commands):
    TeXcommands = @[@"amstex", @"cslatex", @"csplain", @"eplain", @"etex", @"jadetex", @"latex", @"mex", @"mllatex", @"mltex", @"pdfsclatex", @"pdfcsplain", @"pdfetex", @"pdfjadetex", @"pdflatex", @"pdfmex", @"pdftex", @"pdfxmltex", @"tex", @"texsis", @"utf8mex", @"xmltex", @"texlua", @"texluac", @"dvilualatex", @"dviluatex", @"lualatex", @"luatex", @"luahbtex", @"mptopdf", @"optex",
                    @"xetex", @"xelatex", @"dvipdfmx", @"xdvipdfmx",
        @"amstexA", @"cslatexA", @"csplainA", @"eplainA", @"etexA", @"jadetexA", @"latexA", @"mexA", @"mllatexA", @"mltexA", @"pdfsclatexA", @"pdfcsplainA", @"pdfetexA", @"pdfjadetexA", @"pdflatexA", @"pdfmexA", @"pdftexA", @"pdfxmltexA", @"texA", @"texsisA", @"utf8mexA", @"xmltexA", @"texluaA", @"texluacA", @"dvilualatexA", @"dviluatexA", @"lualatexA", @"luatexA", @"luahbtexA", @"mptopdfA", @"optexA",
                    @"xetexA", @"xelatexA",  @"dvipdfmxA", @"xdvipdfmxA"];
}

NSString * pathJoin(NSString * segmentA, NSString * segmentB);
static char* unquoteArgument(char* argument);

static char* parseArgument(char* argument, char* command) {
    // expand all environment variables, convert "~" to $HOME (only if localFile)
    // we also pass the shell command for some specific behaviour (don't do this for that command)
    NSString* argumentString = [NSString stringWithCString:argument encoding:NSUTF8StringEncoding];
    // NSLog(@"parsing argument, argumentString= %s", argumentString.UTF8String);
    // If command == "export", first extract the value string here.
    NSString* variableName;
    if (strcmp(command, "export") == 0) {
        char* equalSign=strchr(argument,'=');
        if (equalSign && (strlen(equalSign) > 0)) {
            char* argumentCString=equalSign+1;
            argumentCString = unquoteArgument(argumentCString);
            variableName = [argumentString substringToIndex:(equalSign - argument)];
            argumentString = [NSString stringWithCString:argumentCString encoding:NSUTF8StringEncoding];
            // NSLog(@"parsing argument, variable name= %s argument= %s", variableName.UTF8String, argumentString.UTF8String);
        } else {
            // No equal sign, or nothing after. export_main will take care of this.
            return argument;
        }
    }
    // 1) expand environment variables, + "~" (not wildcards ? and *)
    bool cannotExpand = false;
    while ([argumentString containsString:@"$"] && !cannotExpand) {
        // It has environment variables inside. Work on them one by one.
        // position of first "$" sign:
        NSRange r1 = [argumentString rangeOfString:@"$"];
        // position of first "/" after this $ sign:
        NSRange r2 = [argumentString rangeOfString:@"/" options:NULL range:NSMakeRange(r1.location + r1.length, [argumentString length] - r1.location - r1.length)];
        // position of first ":" after this $ sign:
        NSRange r3 = [argumentString rangeOfString:@":" options:NULL range:NSMakeRange(r1.location + r1.length, [argumentString length] - r1.location - r1.length)];
        if ((r2.location == NSNotFound) && (r3.location == NSNotFound)) r2.location = [argumentString length];
        else if ((r2.location == NSNotFound) || (r3.location < r2.location)) r2.location = r3.location;
        
        NSRange  rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
        NSString *variable_string = [argumentString substringWithRange:rSub];
        const char* variable = ios_getenv([variable_string UTF8String]);
        if (variable) {
            // Okay, so this one exists.
            variable_string = [[NSString stringWithCString:"$" encoding:NSUTF8StringEncoding] stringByAppendingString:variable_string];
            NSString* replacement_string = [NSString stringWithCString:variable encoding:NSUTF8StringEncoding];
            argumentString = [argumentString stringByReplacingOccurrencesOfString:variable_string withString:replacement_string];
            if ([replacement_string containsString:variable_string]) // avoid an infinite loop here
                cannotExpand = true;
        } else cannotExpand = true; // found a variable we can't expand. stop trying for this argument
    }
    // 2) Tilde conversion: replace "~" with $HOME
    // If there are multiple users on iOS, this code will need to be changed.
    // We also expand ~bookmarkName to the path for that bookmark.
    // 2a) ~ expansion. (old behaviour, kept as is for compatibility)
    if([argumentString hasPrefix:@"~"]) {
        // So it begins with "~". We can't use stringByExpandingTildeInPath because apps redefine HOME
        NSString* replacement_string;
        if (miniRoot == nil)
            replacement_string = [NSString stringWithCString:(getenv("HOME")) encoding:NSUTF8StringEncoding];
        else replacement_string = miniRoot;
        if (([argumentString hasPrefix:@"~/"]) || ([argumentString hasPrefix:@"~:"]) || ([argumentString length] == 1)) {
            NSString* test_string = @"~";
            argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange(0, 1)];
        } else {
            // 2b) expand "~something" with the content of userPreference dictionary (to be set by each app)
            NSDictionary *tildeExpansionDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ios_bookmarkDictionaryName];
            if (tildeExpansionDictionary != nil) {
                NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString:@":/"];
                NSArray<NSString*>* components = [argumentString componentsSeparatedByCharactersInSet:separators];
                NSString* name = [components[0] substringFromIndex:1]; // remove the "~"
                NSString* expandedPath = tildeExpansionDictionary[name];
                if (expandedPath != nil) {
                    argumentString = [argumentString stringByReplacingOccurrencesOfString:components[0] withString:expandedPath options:NULL range:NSMakeRange(0, [components[0] length])];
                }
            }
        }
    }
    // Also convert ":~something" in PATH style variables
    // We don't use these yet, but we could.
    // We do this expansion only for setenv and export
    if ((strcmp(command, "setenv") == 0) || (strcmp(command, "export") == 0)) {
        // This is something we need to avoid if the command is "scp" or "sftp"
        if ([argumentString containsString:@":~"]) {
            NSString* homeDir;
            if (miniRoot == nil) homeDir = [NSString stringWithCString:(getenv("HOME")) encoding:NSUTF8StringEncoding];
            else homeDir = miniRoot;
            // Only 1 possibility: ":~" (same as $HOME)
            if (homeDir.length > 0) {
                NSString* replacement_string = [@":" stringByAppendingString:homeDir];
                if ([argumentString containsString:@":~/"]) {
                    NSString* test_string = @":~/";
                    replacement_string = [replacement_string stringByAppendingString:[NSString stringWithCString:"/" encoding:NSUTF8StringEncoding]];
                    argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string];
                } else if ([argumentString hasSuffix:@":~"]) {
                    NSString* test_string = @":~";
                    argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange([argumentString length] - 2, 2)];
                } else if ([argumentString hasSuffix:@":"]) {
                    NSString* test_string = @":";
                    argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange([argumentString length] - 2, 2)];
                }
            }
            NSDictionary *tildeExpansionDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ios_bookmarkDictionaryName];
            if (tildeExpansionDictionary != nil) {
                // TODO: add :~bookmarkName/ :~bookmarkName
                NSArray<NSString*>* components = [argumentString componentsSeparatedByString:@":~"];
                NSString* result = components[0];
                for (int i = 1; i < components.count; i++) {
                    NSString* stringToAdd = components[i];
                    NSArray<NSString*>* names = [components[i] componentsSeparatedByString:@"/"];
                    NSString* test_string = names[0];
                    NSString* replacement_string = tildeExpansionDictionary[names[0]];
                    if (replacement_string != nil) {
                        // we found a name to expand
                        stringToAdd = [stringToAdd stringByReplacingOccurrencesOfString:test_string withString:replacement_string];
                        result = [[result stringByAppendingString:@":"] stringByAppendingString:stringToAdd];
                    } else {
                        result = [[result stringByAppendingString:@":~"] stringByAppendingString:stringToAdd];
                    }
                }
                argumentString = result;
            }
        }
    }
    if ([argumentString hasPrefix:@"../"] || [argumentString hasPrefix:@"./.."] || [argumentString isEqualToString:@".."]) {
        argumentString = pathJoin(@(currentSession->currentDir), argumentString);
    }
    if (strcmp(command, "export") == 0) {
        argumentString = [[variableName stringByAppendingString:@"="] stringByAppendingString:argumentString];
    }
    const char* newArgument = [argumentString UTF8String];
    // NSLog(@"After parsing: %s", newArgument);
    if (strcmp(argument, newArgument) == 0) return argument; // nothing changed
    // Make sure the argument is reallocated, so it can be free-ed
    char* returnValue = realloc(argument, strlen(newArgument) + 1);
    strcpy(returnValue, newArgument);
    return returnValue;
}

static const char* ios_expandFilename(const char *filename) {
    // expand a filename for opening if it begins with "~" or contains an environment variable
    if (strlen(filename) == 0) return filename;
    NSString* nameString = [NSString stringWithUTF8String:filename];
    if([nameString hasPrefix:@"~"]) {
        // So it begins with "~". We can't use stringByExpandingTildeInPath because apps redefine HOME
        NSString* replacement_string;
        if (miniRoot == nil)
            replacement_string = [NSString stringWithCString:(getenv("HOME")) encoding:NSUTF8StringEncoding];
        else replacement_string = miniRoot;
        if (([nameString hasPrefix:@"~/"]) || ([nameString length] == 1)) {
            NSString* test_string = @"~";
            nameString = [nameString stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange(0, 1)];
        } else {
            // 2b) expand "~something" with the content of userPreference dictionary (to be set by each app)
            NSDictionary *tildeExpansionDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ios_bookmarkDictionaryName];
            if (tildeExpansionDictionary != nil) {
                NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString:@":/"];
                NSArray<NSString*>* components = [nameString componentsSeparatedByCharactersInSet:separators];
                NSString* name = [components[0] substringFromIndex:1]; // remove the "~"
                NSString* expandedPath = tildeExpansionDictionary[name];
                if (expandedPath != nil) {
                    nameString = [nameString stringByReplacingOccurrencesOfString:components[0] withString:expandedPath options:NULL range:NSMakeRange(0, [components[0] length])];
                }
            }
        }
    }
    bool cannotExpand = false;
    while ([nameString containsString:@"$"] && !cannotExpand) {
        // It has environment variables inside. Work on them one by one.
        // position of first "$" sign:
        NSRange r1 = [nameString rangeOfString:@"$"];
        // position of first "/" after this $ sign:
        NSRange r2 = [nameString rangeOfString:@"/" options:NULL range:NSMakeRange(r1.location + r1.length, [nameString length] - r1.location - r1.length)];
        if (r2.location == NSNotFound)  r2.location = [nameString length];
        
        NSRange  rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
        NSString *variable_string = [nameString substringWithRange:rSub];
        const char* variable = ios_getenv([variable_string UTF8String]);
        if (variable) {
            // Okay, so this one exists.
            NSString* replacement_string = [NSString stringWithCString:variable encoding:NSUTF8StringEncoding];
            variable_string = [[NSString stringWithCString:"$" encoding:NSUTF8StringEncoding] stringByAppendingString:variable_string];
            nameString = [nameString stringByReplacingOccurrencesOfString:variable_string withString:replacement_string];
        } else cannotExpand = true; // found a variable we can't expand. stop trying for this fileName
    }
    return [nameString UTF8String];
}



static void initializeCommandList(void)
{
    // Loads command names and where to find them (digital library, function name) from plist dictionaries:
    //
    // Syntax for the dictionaris:
    // key = command name, followed by an array of 4 components:
    // 1st component: name of digital library (will be passed to dlopen(), can be SELF for RTLD_SELF or MAIN for RTLD_MAIN_ONLY)
    // 2nd component: name of function to be called
    // 3rd component: chain sent to getopt (for arguments in autocomplete)
    // 4th component: takes a file/directory as argument
    //
    // Example:
    //    <key>rlogin</key>
    // <array>
    // <string>libnetwork_ios.dylib</string>
    // <string>rlogin_main</string>
    // <string>468EKLNS:X:acde:fFk:l:n:rs:uxy</string>
    // <string>no</string>
    // </array>

    if (commandList != nil) return;
    NSError *error;
    NSString* applicationDirectory = [[NSBundle mainBundle] resourcePath];
    NSString* commandDictionary = [applicationDirectory stringByAppendingPathComponent:@"commandDictionary.plist"];
    NSURL *locationURL = [NSURL fileURLWithPath:commandDictionary isDirectory:NO];
    if ([locationURL checkResourceIsReachableAndReturnError:&error] == NO) { NSLog(@"%@", [error localizedDescription]); return; }
    NSData* loadedFromFile = [NSData dataWithContentsOfFile:commandDictionary  options:0 error:&error];
    if (!loadedFromFile) { NSLog(@"%@", [error localizedDescription]); return; }
    commandList = [NSPropertyListSerialization propertyListWithData:loadedFromFile options:NSPropertyListImmutable format:NULL error:&error];
    if (!commandList) { NSLog(@"%@", [error localizedDescription]); return; }
    // replaces the following command, marked as deprecated in the doc:
    // commandList = [NSDictionary dictionaryWithContentsOfFile:commandDictionary];
    if (sideLoading) {
        // more commands, for sideloaders (commands that won't pass AppStore rules, or with licensing issues):
        NSString* extraCommandsDictionary = [applicationDirectory stringByAppendingPathComponent:@"extraCommandsDictionary.plist"];
        locationURL = [NSURL fileURLWithPath:extraCommandsDictionary isDirectory:NO];
        if ([locationURL checkResourceIsReachableAndReturnError:&error] == NO) { NSLog(@"%@", [error localizedDescription]); return; }
        NSData* extraLoadedFromFile = [NSData dataWithContentsOfFile:extraCommandsDictionary  options:0 error:&error];
        if (!extraLoadedFromFile) { NSLog(@"%@", [error localizedDescription]); return; }
        NSDictionary* extraCommandList = [NSPropertyListSerialization propertyListWithData:extraLoadedFromFile options:NSPropertyListImmutable format:NULL error:&error];
        if (!extraCommandList) { NSLog(@"%@", [error localizedDescription]); return; }
        // merge the two dictionaries:
        NSMutableDictionary *mutableDict = [commandList mutableCopy];
        [mutableDict addEntriesFromDictionary:extraCommandList];
        commandList = [mutableDict copy];
    }
}

int ios_setMiniRoot(NSString* mRoot) {
    BOOL isDir;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    if (![fileManager fileExistsAtPath:mRoot isDirectory:&isDir]) {
      return 0;
    }

    if (!isDir) {
      return 0;
    }

    // fileManager has different ways of expressing the same directory.
    // We need to actually change to the directory to get its "real name".
    NSString* currentDir = [fileManager currentDirectoryPath];

    if (![fileManager changeCurrentDirectoryPath:mRoot]) {
      return 0;
    }
    // also don't set the miniRoot if we can't go in there
    // get the real name for miniRoot:
    miniRoot = [fileManager currentDirectoryPath];
    // Back to where we we before:
    [fileManager changeCurrentDirectoryPath:currentDir];
    if (currentSession != nil) {
        strcpy(currentSession->currentDir, [miniRoot UTF8String]);
        strcpy(currentSession->previousDirectory, [miniRoot UTF8String]);
    }
    return 1; // mission accomplished
}

// Called when 
int ios_setMiniRootURL(NSURL* mRoot) {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (currentSession == NULL) {
        currentSession = malloc(sizeof(sessionParameters));
        initSessionParameters(currentSession);
    }
    strcpy(currentSession->localMiniRoot, [mRoot.path UTF8String]);
    strcpy(currentSession->previousDirectory, currentSession->currentDir);
    strcpy(currentSession->currentDir, [[mRoot path] UTF8String]);
    [fileManager changeCurrentDirectoryPath:[mRoot path]];
    return 1; // mission accomplished
}

int ios_setAllowedPaths(NSArray<NSString *> *paths) {
  allowedPaths = paths;
  return 1;
}

BOOL __allowed_cd_to_path(NSString *path) {
    // NSLog(@"__allowed_cd_to_path: %@ miniRoot: %@\n", path, miniRoot);
    if (miniRoot == nil) {
        return YES;
    }
    if ([path hasPrefix:miniRoot]) {
        return YES;
    }
    if (strlen(currentSession->localMiniRoot) != 0) {
        NSString *localMiniRootPath = [NSString stringWithCString:currentSession->localMiniRoot encoding:NSUTF8StringEncoding];
        // NSLog(@"__allowed_cd_to_path: localMiniRoot: %s\n", localMiniRootPath);
        if (localMiniRootPath && [path hasPrefix:localMiniRootPath]) {
            return YES;
        }
    }
    
    for (NSString *dir in allowedPaths) {
        if ([path hasPrefix:dir]) {
            return YES;
        }
    }
    // NSLog(@"__allowed_cd_to_path: failure, returning NO\n");
    
    return NO;
}

void __cd_to_dir(NSString *newDir, NSFileManager *fileManager) {
  BOOL isDir;
  // Check for permission and existence:
  if (![fileManager fileExistsAtPath:newDir isDirectory:&isDir]) {
    fprintf(thread_stderr, "cd: %s: no such file or directory\n", [newDir UTF8String]);
    return;
  }
  if (!isDir) {
    fprintf(thread_stderr, "cd: %s: not a directory\n", [newDir UTF8String]);
    return;
  }

  if (![fileManager isReadableFileAtPath:newDir] ||
      ![fileManager changeCurrentDirectoryPath:newDir]) {
    fprintf(thread_stderr, "cd: %s: permission denied\n", [newDir UTF8String]);
    return;
  }

  // We managed to change the directory.
  // Was that allowed?
  // Allowed "cd" = below miniRoot *or* below localMiniRoot
  NSString* resultDir = [fileManager currentDirectoryPath];

  if (__allowed_cd_to_path(resultDir)) {
    strcpy(currentSession->previousDirectory, currentSession->currentDir);
    strcpy(currentSession->currentDir, [newDir UTF8String]);
    return;
  }
  
  fprintf(thread_stderr, "cd: %s: permission denied\n", [newDir UTF8String]);
  // If the user tried to go above the miniRoot, set it to miniRoot
  if ([miniRoot hasPrefix:resultDir]) {
    [fileManager changeCurrentDirectoryPath:miniRoot];
    strcpy(currentSession->currentDir, [miniRoot UTF8String]);
    strcpy(currentSession->previousDirectory, currentSession->currentDir);
  } else {
    // go back to where we were before:
    [fileManager changeCurrentDirectoryPath:[NSString stringWithCString:currentSession->currentDir encoding:NSUTF8StringEncoding]];
  }
}

// For some Unix commands that call fchdir (including vim):
#undef fchdir
int ios_fchdir(const int fd) {
    // NSLog(@"Locking for thread %x in ios_fchdir\n", pthread_self());
    while (cleanup_counter > 0) { } // Don't chdir while a command is ending.
    // We cannot have someone change the current directory while a command is starting or terminating.
    // hence the mutex_lock here.
    pthread_mutex_lock(&pid_mtx);
    int result = fchdir(fd);
    if (result < 0) {
        // NSLog(@"Unlocking for thread %x in ios_fchdir\n", pthread_self());
        pthread_mutex_unlock(&pid_mtx);
        return result;
    }
    // We managed to change the directory. Update currentSession as well:
    // Was that allowed?
    // Allowed "cd" = below miniRoot *or* below localMiniRoot
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString* resultDir = [fileManager currentDirectoryPath];
    // NSLog(@"Inside fchdir, path: %s for session: %s\n", resultDir.UTF8String, (char*)currentSession->context);

    if (__allowed_cd_to_path(resultDir)) {
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
        strcpy(currentSession->currentDir, [resultDir UTF8String]);
        errno = 0;
        // NSLog(@"Unlocking for thread %x in ios_fchdir\n", pthread_self());
        pthread_mutex_unlock(&pid_mtx);
        return 0;
    }
    
    errno = EACCES; // Permission denied
    // If the user tried to go above the miniRoot, set it to miniRoot
    if ([miniRoot hasPrefix:resultDir]) {
        [fileManager changeCurrentDirectoryPath:miniRoot];
        strcpy(currentSession->currentDir, [miniRoot UTF8String]);
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
    } else {
        // go back to where we were before:
        [fileManager changeCurrentDirectoryPath:[NSString stringWithCString:currentSession->currentDir encoding:NSUTF8StringEncoding]];
    }
    // NSLog(@"Unlocking for thread %x in ios_fchdir\n", pthread_self());
    pthread_mutex_unlock(&pid_mtx);
    return -1;
}

int ios_fchdir_nolock(const int fd) {
    // NSLog(@"fchdir_nolock: %x thread %x\n", fd, pthread_self());
    // Same function as fchdir, except it does not lock. To be called when resetting directory after fork().
    while (cleanup_counter > 0) { } // Don't chdir while a command is ending.
    int result = fchdir(fd);
    if (result < 0) {
        return result;
    }
    // We managed to change the directory. Update currentSession as well:
    // Was that allowed?
    // Allowed "cd" = below miniRoot *or* below localMiniRoot
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString* resultDir = [fileManager currentDirectoryPath];
    // NSLog(@"fchdir_nolock, success: %s\n", resultDir.UTF8String);

    if (__allowed_cd_to_path(resultDir)) {
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
        strcpy(currentSession->currentDir, [resultDir UTF8String]);
        errno = 0;
        return 0;
    }
    
    errno = EACCES; // Permission denied
    // If the user tried to go above the miniRoot, set it to miniRoot
    if ([miniRoot hasPrefix:resultDir]) {
        [fileManager changeCurrentDirectoryPath:miniRoot];
        strcpy(currentSession->currentDir, [miniRoot UTF8String]);
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
    } else {
        // go back to where we were before:
        [fileManager changeCurrentDirectoryPath:[NSString stringWithCString:currentSession->currentDir encoding:NSUTF8StringEncoding]];
    }
    // NSLog(@"fchdir_nolock, failure\n");
    return -1;
}

int chdir_nolock(const char* path) {
    // NSLog(@"chdir_nolock: %s thread %x\n", path, pthread_self());
    // Same function as chdir, except it does not lock. To be called from ios_releaseThread*()
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString* newDir = @(path);
    BOOL isDir;
    // Check for permission and existence:
    if (![fileManager fileExistsAtPath:newDir isDirectory:&isDir]) {
        errno = ENOENT; // No such file or directory
        return -1;
    }
    if (!isDir) {
        errno = ENOTDIR; // Not a directory
        return -1;
    }
    if (![fileManager isReadableFileAtPath:newDir] ||
        ![fileManager changeCurrentDirectoryPath:newDir]) {
        errno = EACCES; // Permission denied
        return -1;
    }
    
    // We managed to change the directory.
    // Was that allowed?
    // Allowed "cd" = below miniRoot *or* below localMiniRoot
    NSString* resultDir = [fileManager currentDirectoryPath];
    if (resultDir == nil) {
        resultDir = newDir;
    }

    if (__allowed_cd_to_path(resultDir)) {
        if (currentSession != NULL) {
            strcpy(currentSession->currentDir, [resultDir UTF8String]);
        }
        NSLog(@"allowed directory change, returning\n");
        errno = 0;
        return 0;
    }
    
    errno = EACCES; // Permission denied
    // If the user tried to go above the miniRoot, set it to miniRoot
    if ([miniRoot hasPrefix:resultDir]) {
        [fileManager changeCurrentDirectoryPath:miniRoot];
        strcpy(currentSession->currentDir, [miniRoot UTF8String]);
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
    } else {
        // go back to where we were before:
        [fileManager changeCurrentDirectoryPath:[NSString stringWithCString:currentSession->currentDir encoding:NSUTF8StringEncoding]];
    }
    return -1;
}

// For some Unix commands that call chdir:
// Is also called at the end of the execution of each command
int chdir(const char* path) {
    while (cleanup_counter > 0) { } // Don't chdir while a command is ending.
    // NSLog(@"Locking for thread %x in chdir, cd %s\n", pthread_self(), path);
    // We cannot have someone change the current directory while a command is starting or terminating.
    // hence the mutex_lock here.
    pthread_mutex_lock(&pid_mtx);
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString* newDir = @(path);
    BOOL isDir;
    // Check for permission and existence:
    if (![fileManager fileExistsAtPath:newDir isDirectory:&isDir]) {
        errno = ENOENT; // No such file or directory
        // NSLog(@"Unlocking for thread %x in chdir (no such directory)\n", pthread_self());
        pthread_mutex_unlock(&pid_mtx);
        return -1;
    }
    if (!isDir) {
        errno = ENOTDIR; // Not a directory
        // NSLog(@"Unlocking for thread %x in chdir (not a directory)\n", pthread_self());
        pthread_mutex_unlock(&pid_mtx);
        return -1;
    }
    if (![fileManager isReadableFileAtPath:newDir] ||
        ![fileManager changeCurrentDirectoryPath:newDir]) {
        errno = EACCES; // Permission denied
        // NSLog(@"Unlocking for thread %x in chdir (not readable)\n", pthread_self());
        pthread_mutex_unlock(&pid_mtx);
        return -1;
    }
    
    // We managed to change the directory.
    // Was that allowed?
    // Allowed "cd" = below miniRoot *or* below localMiniRoot
    NSString* resultDir = [fileManager currentDirectoryPath];
    // NSLog(@"After changing directory, result= %s\n", resultDir.UTF8String);

    if (__allowed_cd_to_path(resultDir)) {
        if (currentSession != NULL) {
            strcpy(currentSession->currentDir, [resultDir UTF8String]);
        }
        // NSLog(@"Unlocking for thread %x in chdir (allowed)\n", pthread_self());
        pthread_mutex_unlock(&pid_mtx);
        errno = 0;
        return 0;
    }
    
    errno = EACCES; // Permission denied
    if (currentSession == NULL) {
        return -1   ;
    }
    // If the user tried to go above the miniRoot, set it to miniRoot
    if ([miniRoot hasPrefix:resultDir]) {
        [fileManager changeCurrentDirectoryPath:miniRoot];
        strcpy(currentSession->currentDir, [miniRoot UTF8String]);
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
    } else {
        // go back to where we were before:
        [fileManager changeCurrentDirectoryPath:[NSString stringWithCString:currentSession->currentDir encoding:NSUTF8StringEncoding]];
    }
    // NSLog(@"Unlocking for thread %lx in chdir (not allowed)\n", (unsigned long)pthread_self());
    pthread_mutex_unlock(&pid_mtx);
    return -1;
}

int too_many_scripts(int argc, char** argv) {
    // Call an actual command in order to go through run_function / cleanup_function
    // But not something as hardcore as causing a "Command not found" error:
    if (currentSession->global_errno == 0) {
        return 0; // show the warning only once for PythonNum commands stored:
    }
    fprintf(thread_stderr, "%s: too many scripts already running\n", argv[0]);
    NSLog(@"%s: command not found\n", argv[0]);
    return currentSession->global_errno;
}

int command_not_found(int argc, char** argv) {
    // Call an actual command in order to go through run_function / cleanup_function
    fprintf(thread_stderr, "%s: command not found\n", argv[0]);
    NSLog(@"%s: command not found\n", argv[0]);
    currentSession->global_errno = 127;
    return 127;
    // TODO: this should also raise an exception, for python scripts
}

int xcode_select(int argc, char** argv) {
    // Replacement for xcode-select so config.guess scripts work
    currentSession->global_errno = 1;
    errno = 1;
    return 1;
}

int sw_vers(int argc, char** argv) {
    // Small command to make tlmgr happy
    // tlmgr calls "sw_vers -productVersion". We return the latest OSX version, for simplicity
    fprintf(thread_stdout, "11.5.2");
    fflush(thread_stdout);
    return 0;
}

extern void newPreviousDirectory(void);

int cd_main(int argc, char** argv) {
    if (currentSession == NULL) {
      return 1;
    }
    NSFileManager *fileManager = [[NSFileManager alloc] init];
  
    if (argc > 1) {
        NSString* newDir = @(argv[1]);
        if (strcmp(argv[1], "-") == 0) {
            // "cd -" option to pop back to previous directory
            newDir = @(currentSession->previousDirectory);
        }
        newDir = pathJoin(@(currentSession->currentDir), newDir);
        // Store directory usage for autocomplete:
        // It should not be a dictionary. NSArray? NSMutableArray?
        // Need to store directoryname + number of times = sounds a lot like a Swift dictionary.
        // But not Objective-C? Weird.
        // Do it in Swift (new dictionary each time), then store it, then move to Objective-C?
        void (*function)(NSString*) = NULL;
        function = dlsym(RTLD_MAIN_ONLY, "storeDirectoryUsed");
        if (function != NULL) {
            NSString *key = @(ios_getBookmarkedVersion(newDir.UTF8String));
            function(key);
        }
        __cd_to_dir(newDir, fileManager);
    } else { // [cd] Help, I'm lost, bring me back home
        if (miniRoot != nil) {
            [fileManager changeCurrentDirectoryPath:miniRoot];
        } else {
            [fileManager changeCurrentDirectoryPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
        }
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
        strcpy(currentSession->currentDir, fileManager.currentDirectoryPath.UTF8String);
    }

    newPreviousDirectory(); // If a command is running, this changes the directory it goes back to.
    return 0;
}

NSString* getoptString(NSString* commandName) {
    if (commandList == nil) initializeCommandList();
    NSArray* commandStructure = [commandList objectForKey: commandName];
    if (commandStructure != nil) return commandStructure[2];
    else return @"";
}

NSString* operatesOn(NSString* commandName) {
    if (commandList == nil) initializeCommandList();
    NSArray* commandStructure = [commandList objectForKey: commandName];
    if (commandStructure != nil) return commandStructure[3];
    else return @"";
}


int ios_executable(const char* inputCmd) {
    // returns 1 if this is one of the commands we define in ios_system, 0 otherwise
    if (commandList == nil) initializeCommandList();
    // Take basename in case someone put a path before:
    NSArray* valuesFromDict = [commandList objectForKey: [NSString stringWithCString:basename(inputCmd) encoding:NSUTF8StringEncoding]];
    // we could dlopen() here, but that would defeat the purpose
    if (valuesFromDict == nil) return 0;
    else return 1;
}

// Where to direct input/output of the next thread:
static __thread FILE* child_stdin = NULL;
static __thread FILE* child_stdout = NULL;
static __thread FILE* child_stderr = NULL;

FILE* ios_popen(const char* inputCmd, const char* type) {
    // NSLog(@"ios_popen: %s mode %s", inputCmd, type);
    // Save existing streams:
    int fd[2] = {0};
    const char* command = inputCmd;
    // skip past all spaces
    while ((command[0] == ' ') && strlen(command) > 0) command++;
    if (pipe(fd) < 0) { return NULL; } // Nothing we can do if pipe fails
    // F_SETNOSIGPIPE: don't cause a signal 13 if the pipe is already closed
    fcntl(fd[0], F_SETNOSIGPIPE);
    fcntl(fd[1], F_SETNOSIGPIPE);
    // NOTES: fd[0] is set up for reading, fd[1] is set up for writing
    // fpout = fdopen(fd[1], "w");
    // fpin = fdopen(fd[0], "r");
    if (type[0] == 'w') {
        // open pipe for reading
        child_stdin = fdopen(fd[0], "r");
        // launch command: if the command fails, return NULL.
        int returnValue = ios_system(command);
        if (returnValue == 0)
            return fdopen(fd[1], "w");
    } else if (type[0] == 'r') {
        // open pipe for writing
        // set up streams for thread
        child_stdout = fdopen(fd[1], "w");
        // launch command: if the command fails, return NULL.
        int returnValue = ios_system(command);
        if (returnValue == 0)
            return fdopen(fd[0], "r");
    }
    // pipe creation failed, command starting failed:
    return NULL;
}

// small function, behaves like strstr but skips quotes (Yury Korolev)
char *strstrquoted(char* str1, char* str2) {
    
    if (str1 == NULL || str2 == NULL) {
        return NULL;
    }
    size_t len1 = strlen(str1);
    size_t len2 = strlen(str2);
    
    if (len1 < len2) {
        return NULL;
    }
    
    if (strcmp(str1, str2) == 0) {
        return str1;
    }
    
    char quotechar = 0;
    int esclen = 0;
    int matchlen = 0;
    
    for (int i = 0; i < len1; i++) {
        char ch = str1[i];
        if (quotechar) {
            if (ch == '\\') {
                esclen++;
                continue;
            }
            
            if (ch == quotechar) {
                if (esclen % 2 == 1) {
                    esclen = 0;
                    continue;
                }
                quotechar = 0;
                esclen = 0;
                continue;
            }
            
            esclen = 0;
            continue;
        }
        
        if (ch == '"' || ch == '\'') {
            if (esclen % 2 == 0) {
                quotechar = ch;
            }
            matchlen = 0;
            esclen = 0;
            continue;
        }
        
        if (ch == '\\') {
            esclen++;
        }
        
        if (str2[matchlen] == ch) {
            matchlen++;
            if (matchlen == len2) {
                return str1 + i - matchlen + 1;
            }
            continue;
        }
        
        matchlen = 0;
    }
    return NULL;
}

static char* concatenateArgv(char* const argv[]) {
    int argc = 0;
    int cmdLength = 0;
    // concatenate all arguments into a big command.
    // We need this because some programs call execv() with a single string: "ssh hg@bitbucket.org 'hg -R ... --stdio'"
    // So we rely on ios_system to break them into chunks.
    while(argv[argc] != NULL) { cmdLength += strlen(argv[argc]) + 1; argc++;}
    if (argc == 0) return NULL; // safeguard check
    char* cmd = malloc((cmdLength  + 3 * argc + 1) * sizeof(char)); // space for quotes
    strcpy(cmd, argv[0]);
    argc = 1;
    char recordSeparator = 0x1e;
    while (argv[argc] != NULL) {
        if (strstrquoted(argv[argc], " ")) {
            // argument contains spaces. Enclose it into quotes:
            if (strstr(argv[argc], "\"") == NULL) { // We're looking for quotes, so strstr, not strstrquoted
                // argument does not contain ". Enclose with "
                strcat(cmd, " \"");
                strcat(cmd, argv[argc]);
                strcat(cmd, "\"");
                argc++;
                continue;
            } else if (strstr(argv[argc], "'") == NULL) { // We're looking for quotes, so strstr, not strstrquoted
                // argument does not contain '. Enclose with '
                strcat(cmd, " '");
                strcat(cmd, argv[argc]);
                strcat(cmd, "'");
                argc++;
                continue;
            } else if (strchr(argv[argc], recordSeparator) == NULL) {
                // Argument contains spaces and double and single quotes. We use recordSeparator to mark begin and end:
                strcat(cmd, " ");
                strncat(cmd, &recordSeparator, 1);
                strcat(cmd, argv[argc]);
                strncat(cmd, &recordSeparator, 1);
                argc++;
                continue;
            }
            NSLog(@"Argument contains spaces, double quotes, single quotes and recordSeparator");
        }
        strcat(cmd, " ");
        strcat(cmd, argv[argc]);
        argc++;
    }
    return cmd;
}

int pbpaste(int argc, char** argv) {
    if (argc == 1) {
        // We can paste strings and URLs.
        if ([UIPasteboard generalPasteboard].hasStrings) {
            fprintf(thread_stdout, "%s", [[UIPasteboard generalPasteboard].string UTF8String]);
            if (![[UIPasteboard generalPasteboard].string hasSuffix:@"\n"]) fprintf(thread_stdout, "\n");
            return 0;
        }
        if ([UIPasteboard generalPasteboard].hasURLs) {
            fprintf(thread_stdout, "%s\n", [[[UIPasteboard generalPasteboard].URL absoluteString] UTF8String]);
            return 0;
        }
    } else {
        fprintf(thread_stderr, "Usage: pbpaste\nPastes the content of the copy buffer (strings or urls).");
    }
    return 1;
}


int pbcopy(int argc, char** argv) {
    if (argc == 1) {
        // no arguments, listen to stdin
        const int bufsize = 1024;
        char buffer[bufsize];
        NSMutableData* data = [[NSMutableData alloc] init];
        
        ssize_t count = 0;
        while ((count = read(fileno(thread_stdin), buffer, bufsize-1))) {
            [data appendBytes:buffer length:count];
        }
        
        NSString* result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (!result) {
            return 1;
        }
        
        [UIPasteboard generalPasteboard].string = result;
    } else {
        if ((argv[1][0] == '-') && ((strcmp(argv[1], "-h") == 0) || (strcmp(argv[1], "--help") == 0))) {
            fprintf(thread_stderr, "Usage: pbcopy arguments\ncommand > pbcopy\nCopies either its arguments or input to the copy buffer.");
            return 0;
        }
        // threre are arguments, concatenate and paste:
        char* cmd = concatenateArgv(argv + 1);
        [UIPasteboard generalPasteboard].string = @(cmd);
        free(cmd);
    }
    return 0;
}

int true_main(int argc, char** argv) {
    return 0;
}
int type_main(int argc, char** argv) {
    // Minimalist implementation of type to keep make happy
    if (argc < 2) { return 1; }
    fprintf(thread_stdout, "%s is %s\n", argv[1], argv[1]);
    return 0;
}

int alias_main(int argc, char** argv) {
    // Syntax: alias command="new command" or alias command "new command" (both must work)
    // alias -h or alias --help: print help
    // alias (no arguments): print list of aliases
    // alias (single argument): print corresponding alias
    NSString* usage = @"usage: alias command new command\n\talias command=new command\n\t!^ = first argument\n\t!* = all arguments";
    if (aliasDictionary == nil) {
        aliasDictionary = [NSMutableDictionary new];
    }
    if (argc <= 1) {
        // no arguments: print list of aliases
        for (NSString* command in aliasDictionary) {
            NSArray<NSString*>* aliasArray = aliasDictionary[command];
            fprintf(thread_stdout, "%s\t", command.UTF8String);
            fprintf(thread_stdout, "%s", aliasArray[0].UTF8String);
            if ([aliasArray[2] isEqualToString: @"afterFirst"]) {
                fprintf(thread_stdout, " !^ %s", aliasArray[1].UTF8String);
            } else if ([aliasArray[2] isEqualToString: @"afterLast"]) {
                fprintf(thread_stdout, " !* %s", aliasArray[1].UTF8String);
            }
            fprintf(thread_stdout, "\n");
        }
        return 0;
    }
    if (argv[1][0] == '-') {
        if ((strncmp(argv[1], "-h", 2) != 0) && (strncmp(argv[1], "--help", 6) != 0)) {
            fprintf(thread_stderr, "alias: unrecognized option %s\n", argv[1]);
        }
        fprintf(thread_stderr, "%s\n", usage.UTF8String);
        return 0;
    }
    char* equalSign = strchr(argv[1], '=');
    NSString* command = nil;
    if ((equalSign == NULL) && (argc == 2)) {
        // single command, show alias:
        command =  [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSLog(@"Extracting alias for command %s = %@.", argv[1], command);
        NSArray<NSString*>* aliasArray = aliasDictionary[command];
        if (aliasArray == nil) { return 0; }
        fprintf(thread_stdout, "%s", aliasArray[0].UTF8String);
        if ([aliasArray[2] isEqualToString: @"afterFirst"]) {
            fprintf(thread_stdout, " !^ %s", aliasArray[1].UTF8String);
        } else if ([aliasArray[2] isEqualToString: @"afterLast"]) {
            fprintf(thread_stdout, " !* %s  ", aliasArray[1].UTF8String);
        }
        fprintf(thread_stdout, "\n");
        return 0;
    }
    NSMutableArray<NSString *> *commandArray = [[NSMutableArray alloc] init];
    if (equalSign != NULL) {
        // There is an equal sign in the second argument. Split into alias / command:
        equalSign[0] = 0;
        char* alias = equalSign + 1;
        command =  [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        commandArray[0] = [NSString stringWithCString:alias encoding:NSUTF8StringEncoding];;
    } else {
        command =  [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    }
    if (argc >= 3) {
        // We keep the benefit of the parsing that was already done:
        for (int i = 0; i < argc - 2; i++) {
            [commandArray addObject: [NSString stringWithCString:argv[i + 2] encoding:NSUTF8StringEncoding]];
        }
    }
    if ((command == nil) || (commandArray == nil) || (commandArray.count == 0)) {
        // Something went wrong
        return 1;
    }
    if ((equalSign != NULL) || (commandArray.count == 1)) {
        // If there was an equal sign, so there might be some extra quotes:
        // Observed decomposition with equal sign: "ll=\"ls" + "-l\""
        // If there is a single command, we separate it as well: alias ls "ls -l"
        if ([commandArray[0] hasPrefix:@"\""] && [[commandArray lastObject] hasSuffix:@"\""]) {
            commandArray[0] = [commandArray[0] substringFromIndex:1];
            commandArray[commandArray.count - 1] = [[commandArray lastObject] substringToIndex:[[commandArray lastObject] length] -1];
        } else if ([commandArray[0] hasPrefix:@"'"] && [[commandArray lastObject] hasSuffix:@"'"]) {
            commandArray[0] = [commandArray[0] substringFromIndex:1];
            commandArray[commandArray.count - 1] = [[commandArray lastObject] substringToIndex:[[commandArray lastObject] length] -1];
        }
    }
    if (commandArray.count == 1) {
        char* aliasCommandCString = strdup(commandArray[0].UTF8String);
        char* pointerToFree = aliasCommandCString;
        char* nextSpace = strstrquoted(aliasCommandCString, " ");
        int i = 0;
        while (nextSpace != NULL) {
            *nextSpace = 0;
            commandArray[i] = [NSString stringWithCString:aliasCommandCString encoding:NSUTF8StringEncoding];
            // NSLog(@"Adding %s to array.", aliasCommandCString);
            aliasCommandCString = nextSpace + 1;
            if (*aliasCommandCString == 0) {
                break;
            }
            nextSpace = strstrquoted(aliasCommandCString, " ");
            i += 1;
        }
        if (*aliasCommandCString != 0) {
            // NSLog(@"Adding %s to array.", aliasCommandCString);
            commandArray[i] = [NSString stringWithCString:aliasCommandCString encoding:NSUTF8StringEncoding];
        }
        free(pointerToFree);
    }
    NSString* before = @"";
    NSString* after = @"";
    NSString* position = @"";
    if (([commandArray containsObject:@"!^"]) && ([commandArray containsObject:@"!*"])) {
        fprintf(thread_stderr, "alias: can't pecify both !^ and !*, sorry.\n", argv[1]);
        return 1;
    } else if ([commandArray containsObject:@"!^"]) {
        position = @"afterFirst";
        bool foundMarker = false;
        for (NSString* component in commandArray) {
            if ([component isEqualToString: @"!^"]) { foundMarker = true; continue; }
            if (!foundMarker) {
                before = [before stringByAppendingString: component];
                before = [before stringByAppendingString: @" "];
            } else {
                after = [after stringByAppendingString: component];
                after = [after stringByAppendingString: @" "];
            }
        }
    } else if ([commandArray containsObject:@"!*"]) {
        position = @"afterLast";
        bool foundMarker = false;
        for (NSString* component in commandArray) {
            if ([component isEqualToString:@"!*"]) {
                foundMarker = true;
                continue;
            }
            if (!foundMarker) {
                before = [before stringByAppendingString: component];
                before = [before stringByAppendingString: @" "];
            } else {
                after = [after stringByAppendingString: component];
                after = [after stringByAppendingString: @" "];
            }
        }
    } else {
        for (NSString* component in commandArray) {
            before = [before stringByAppendingString: component];
            before = [before stringByAppendingString: @" "];
        }
    }
    before = [before stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    after = [after stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    NSArray<NSString *> *result = @[before, after, position];
    aliasDictionary[command] = result;
    return 0;
}

NSString* aliasedCommand(NSString* command) {
    if ([command hasPrefix:@"\\"]) {
        // \command = cancel aliasing
        return [command substringFromIndex:1];
    }
    if (aliasDictionary == nil) {
        return command;
    }
    NSArray<NSString*>* aliasArray = aliasDictionary[command];
    if (aliasArray == nil) {
        return command;
    }
    NSString* result = aliasArray[0];
    if ([aliasArray[2] isEqualToString: @"afterFirst"]) {
        result = [[result stringByAppendingString:@" !^ "] stringByAppendingString: aliasArray[1]];
    } else if ([aliasArray[2] isEqualToString: @"afterLast"]) {
        result = [[result stringByAppendingString:@" !* "] stringByAppendingString: aliasArray[1]];
    }
    return result;
}

int unalias_main(int argc, char** argv) {
    NSString* usage = @"usage: unalias [command|-a]";
    if (aliasDictionary == nil) {
        aliasDictionary = [NSMutableDictionary new];
    }
    if ((argc == 1) || ((argv[1][0] == '-') && (strncmp(argv[1], "-a", 2) != 0))) {
        fprintf(thread_stderr, "%s\n", usage.UTF8String);
        return 0;
    }
    if (strncmp(argv[1], "-a", 2) == 0) {
        [aliasDictionary removeAllObjects];
        return 0;
    }
    for (int i = 1; i < argc; i++) {
        NSString* command =  [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
        [aliasDictionary removeObjectForKey: command];
    }
    return 0;
}

// Auxiliary function for sh_main. Given a string of characters (command1 && command2),
// split it into the sub commands and execute each of them in sequence:
static int splitCommandAndExecute(char* command) {
    // Remember to use fork / waitpid to wait for the commands to finish
    if (command == NULL) return 0;
    char* maxPointer = command + strlen(command);
    int returnValue = 0;
    while (command[0] != 0) {
        // NSLog(@"stdout %x \n", fileno(thread_stdout));
        // NSLog(@"stderr %x \n", fileno(thread_stderr));
        char* nextAnd = strstrquoted(command, "&&");
        char* nextOr = strstrquoted(command, "||");
        if ((nextAnd == NULL) && (nextOr == NULL)) {
            // Only one command left
            pid_t pid = ios_fork();
            returnValue = ios_system(command);
            NSLog(@"Started command, stored last_thread= %x pid: %d", currentSession->lastThreadId, pid);
            ios_waitpid(pid);
            break;
        }
        long nextCommandPosition = 0;
        bool andNextCommand = false;
        if (nextAnd != NULL) {
            nextCommandPosition = nextAnd - command;
            andNextCommand = true;
        }
        if (nextOr != NULL) {
            if (nextOr - command < nextCommandPosition) {
                nextCommandPosition = nextOr - command;
                andNextCommand = false;
            }
        }
        command[nextCommandPosition] = 0; // terminate string
        pid_t pid = ios_fork();
        returnValue = ios_system(command);
        NSLog(@"Started command (2), stored last_thread= %x", currentSession->lastThreadId);
        ios_waitpid(pid);
        if (andNextCommand && (returnValue != 0)) {
            // && + the command returned error, we return:
            break;
        } else if (!andNextCommand && (returnValue == 0)) {
            // || + the command worked, we return:
            break;
        }
        command += (nextCommandPosition + 2); // char after "&&" or "||"
        while ((command[0] == ' ') && (command < maxPointer)) command++; // skip spaces
        if (command > maxPointer) return 0; // happens if the command ends with && or ||
    }
    return returnValue;
}

sessionParameters* parentSession = NULL;

// TODO: we *do* have multiple sh sessions running. We will need some way to make this safe.
//
NSString* parentDir;
int sh_main(int argc, char** argv) {
    // NOT an actual shell.
    // for commands that call other commands as "sh -c command" or "sh -c command1 && command2"
    // NSLog(@"sh_main, stdout %d \n", fileno(thread_stdout));
    // NSLog(@"sh_main, stderr %d \n", fileno(thread_stderr));
    if ((argc < 2) || (strncmp(argv[1], "-h", 2) == 0)) {
        fprintf(thread_stderr, "Not an actual shell. sh is provided for compatibility with commands that call other commands.\n");
        fprintf(thread_stderr, "Usage: sh [-flags] [VAR=value] command: executes command (all flags are ignored, environment variable VAR is set to value).\n");
        fprintf(thread_stderr, "       sh [-flags] command1 && command2 [&& command3 && ...]: executes the commands, in order, until one returns error.\n");
        fprintf(thread_stderr, "       sh [-flags] command1 || command2 [|| command3 || ...]: executes the commands, in order, until one returns OK.\n");
        argv[0][0] = 'h'; // prevent termination in cleanup_function
        return 0;
    }
    char** command = argv + 1; // skip past "sh"
    while ((command[0] != NULL) && (command[0][0] == '-')) { command++; } // skip past all flags
    // Anything after "sh" that contains an equal sign must be an environment variable. Pass it to ios_setenv.
    while (command[0] != NULL) {
        char* position = strstrquoted(command[0],"=");
        if (position == NULL) { break; }
        char* firstSpace = strstrquoted(command[0]," ");
        if ((firstSpace!=NULL) && (firstSpace < position)) { break; }
        firstSpace = strstrquoted(position," ");
        if (firstSpace != NULL) { *firstSpace = 0; }
        *position = 0;
        ios_setenv(command[0], position+1, 1);
        if (firstSpace != NULL) {
            command[0] = firstSpace + 1;
        }
        else { command++; }
    }
    if (command[0] == NULL) {
        argv[0][0] = 'h'; // prevent termination in cleanup_function
        return 0;
    }
    // Did we redirect output? (most of the time, yes)
    if ((fileno(currentSession->stdout) == fileno(thread_stdout)) ||
        (fileno(currentSession->stderr) == fileno(thread_stderr)) ||
        (fileno(currentSession->stdout) == fileno(thread_stderr))) {
        NSLog(@"prevent termination in cleanup_function");
        argv[0][0] = 'h'; // prevent termination in cleanup_function
    }
    // If there is a single command (no && or ||), no need to create a new session.
    int i = 0;
    while ((command[i] != NULL) && (strstrquoted(command[i], "&&") == NULL) && (strstrquoted(command[i], "||") == NULL)) i++;
    if (command[i] == NULL) {
        // Just one command:
        char* newCommand = concatenateArgv(command);
        // Only one command left
        argv[0][0] = 'h';  // prevent termination?
        pid_t pid = ios_fork();
        int returnValue = ios_system(newCommand);
        ios_waitpid(pid);
        free(newCommand);
        return returnValue;
    }
    // If we reach this point, we have multiple commands to execute.
    // Store current sesssion, create a new session specific for this, execute commands
    id sessionKey = @((NSUInteger)sh_session);
    if (sessionList != nil) {
        sessionParameters* runningShellSession = (sessionParameters*)[[sessionList objectForKey: sessionKey] pointerValue];
        if (runningShellSession != NULL) {
            if ((runningShellSession->lastThreadId != 0) && (runningShellSession->lastThreadId != pthread_self())) {
                fprintf(thread_stderr, "Sorry, you cannot run sh while another sh command is running\n");
                NSLog(@"There is another sh session running: last_thread= %x", runningShellSession->lastThreadId);
                argv[0][0] = 'h'; // prevent termination in cleanup_function
                return 1;
            } else {
                NSLog(@"There is another sh session running: last_thread= %x us= %x. Continuing.", runningShellSession->lastThreadId, pthread_self());
            }
        }
    }
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSLog(@"parentSession = %x currentSession = %x currentDir = %s\n", parentSession, currentSession, [fileManager currentDirectoryPath].UTF8String);
    if (currentSession->context == sh_session) {
        NSLog(@"We cannot have a sh command starting a sh command");
        return 1; // We cannot have a sh command starting a sh command.
    }
    if (parentSession == NULL) {
        parentSession = currentSession;
        parentDir = [fileManager currentDirectoryPath];
    }
    ios_switchSession(sh_session); // create a new session
    // NSLog(@"after switchSession, currentDir = %s\n", [fileManager currentDirectoryPath].UTF8String);
    currentSession->isMainThread = false;
    currentSession->context = sh_session;
    currentSession->stdin = thread_stdin;
    currentSession->stdout = thread_stdout;
    currentSession->stderr = thread_stderr;
    currentSession->current_command_root_thread = NULL;
    currentSession->lastThreadId = NULL;
    currentSession->mainThreadId = parentSession->mainThreadId;
    // Need to loop twice: over each argument, and inside each argument.
    // &&: keep computing until one command is in error
    // ||: keep computing until one command is not in error
    // Remember to use fork / waitpid to wait for the commands to finish
    int returnValue = 0;
    while (command[0] != NULL) {
        int i = 0;
        while ((command[i] != NULL) && (strcmp(command[i], "&&") != 0) && (strcmp(command[i], "||") != 0)) i++;
        if (command[i] == NULL) {
            char* lastCommand = concatenateArgv(command);
            returnValue = splitCommandAndExecute(lastCommand);
            free(lastCommand);
            break;
        }
        bool andNextCommand = (strcmp(command[i], "&&") == 0); // should we continue?
        command[i] = NULL;
        char* newCommand = concatenateArgv(command);
        returnValue = splitCommandAndExecute(newCommand);
        free(newCommand);
        if (andNextCommand && (returnValue != 0)) {
            // && + the command returned error, we return:
            break;
        } else if (!andNextCommand && (returnValue == 0)) {
            // || + the command worked, we return:
            break;
        }
        command += (i+1);
    }
    // NSLog(@"Closing shell session; last_thread= %x root= %x", currentSession->lastThreadId, currentSession->current_command_root_thread);
    if (![parentDir isEqualToString:[fileManager currentDirectoryPath]]) {
        // NSLog(@"Reset current Dir to= %s instead of %s", parentDir.UTF8String, [fileManager currentDirectoryPath].UTF8String);
        [fileManager changeCurrentDirectoryPath:parentDir];
    }
    ios_closeSession(sh_session);
    currentSession = parentSession;
    parentSession = NULL;
    return returnValue;
}


int ios_execv(const char *path, char* const argv[]) {
    // path and argv[0] are the same (not in theory, but in practice, since Python wrote the command)
    // start "child" with the child streams:
    char* cmd = concatenateArgv(argv);
    int returnValue = ios_system(cmd);
    free(cmd);
    return returnValue;
}

int ios_execve(const char *path, char* const argv[], char* envp[]) {
    // save the environment (done) and current dir (TODO)
    storeEnvironment(envp);
    int returnValue = ios_execv(path, argv);
    // The environment will be restored to previous value when the thread Id is released.
    return returnValue;
}

extern char** environmentVariables(pid_t pid);
NSArray* environmentAsArray(void) {
    char** env_pid = environmentVariables(ios_currentPid());
    NSMutableArray<NSString*> *dictionary = [[NSMutableArray alloc]init];
    int i = 0;
    while (env_pid[i] != NULL) {
        NSString* variable =  [NSString stringWithCString:env_pid[i] encoding:NSUTF8StringEncoding];
        [dictionary addObject:variable];
        i++;
    }
    return [dictionary copy];
}

pthread_t ios_getLastThreadId(void) {
    if (!currentSession) return nil;
    return (currentSession->lastThreadId);
}

/*
 * Public domain dup2() lookalike
 * by Curtis Jackson @ AT&T Technologies, Burlington, NC
 * electronic address:  burl!rcj
 * Edited for iOS by N. Holzschuch.
 * The idea is that dup2(fd, [012]) is usually called between fork and exec.
 *
 * dup2 performs the following functions:
 *
 * Check to make sure that fd1 is a valid open file descriptor.
 * Check to see if fd2 is already open; if so, close it.
 * Duplicate fd1 onto fd2; checking to make sure fd2 is a valid fd.
 * Return fd2 if all went well; return BADEXIT otherwise.
 */

int ios_dup2(int fd1, int fd2)
{
    NSLog(@"ios_dup2: %d %d", fd1, fd2);
    // iOS specifics: trying to access stdin/stdout/stderr?
    if (fd1 < 3) {
        // specific cases like dup2(STDOUT_FILENO, STDERR_FILENO)
        FILE* stream1 = NULL;
        switch (fd1) {
            case 0: stream1 = child_stdin; break;
            case 1: stream1 = child_stdout; break;
            case 2: stream1 = child_stderr; break;
        }
        switch (fd2) {
            case 0:
                if (stream1 != NULL) {
                    child_stdin = stream1; return fd2;
                } else break;
            case 1:
                if (stream1 != NULL) {
                    child_stdout = stream1; return fd2;
                } else break;
            case 2:
                if (stream1 != NULL) {
                    child_stderr = stream1; return fd2;
                } else break;
        }
    }
    // We can have fileno(thread_stdin) == 1. Most likely fd2 == 1 means stdout in that case.
    if (fd2 == 0) {
        child_stdin = fdopen(fd1, "rb");
    } else if (fd2 == 1) {
        child_stdout = fdopen(fd1, "wb");
    } else if (fd2 == 2) {
        if ((child_stdout != NULL) && (fileno(child_stdout) == fd1)) child_stderr = child_stdout;
        if ((thread_stdout != NULL) && (fileno(thread_stdout) == fd1)) child_stderr = child_stdout;
        else if (fd1 == 1) {
            child_stderr = thread_stdout;
        } else child_stderr = fdopen(fd1, "wb");
    } else if (thread_stdin != NULL && fd2 == fileno(thread_stdin)) {
        child_stdin = fdopen(fd1, "rb");
    } else if (thread_stdout != NULL && fd2 == fileno(thread_stdout)) {
        child_stdout = fdopen(fd1, "wb");
    } else if (thread_stderr != NULL && fd2 == fileno(thread_stderr)) {
        if ((child_stdout != NULL) && (fileno(child_stdout) == fd1)) child_stderr = child_stdout;
        else child_stderr = fdopen(fd1, "wb");
    }
    else if (fd1 != fd2) {
        if (fcntl(fd1, F_GETFL) < 0)
            return -1;
        if (fcntl(fd2, F_GETFL) >= 0)
            close(fd2);
        if (fcntl(fd1, F_DUPFD, fd2) < 0)
            return -1;
    }
    return fd2;
}

/* Normally, a command that wants to send output to different streams calls dup2, then fork and exec.
   ios_system() is ready for that. Sometimes, command (eg in dash) just call dup2 and expect the
   output to be redirected. This function sends the result of dup2 to stdin, stdout, stderr and stores
   the previous streams so they can be restored later.
 */

void ios_activateChildStreams(FILE** old_stdin, FILE** old_stdout,  FILE ** old_stderr) {
    if (child_stdin != NULL) {
        *old_stdin = thread_stdin;
        thread_stdin = child_stdin;
        child_stdin = NULL;
    }
    if (child_stdout != NULL) {
        *old_stdout = thread_stdout;
        thread_stdout = child_stdout;
        child_stdout = NULL;
    }
    if (child_stderr != NULL) {
        *old_stderr = thread_stderr;
        thread_stderr = child_stderr;
        child_stderr = NULL;
    }
}

int ios_kill(void)
{
    if (currentSession == NULL) return ESRCH;
    if (currentSession->current_command_root_thread > 0) {
        struct sigaction query_action;
        if ((sigaction (SIGINT, NULL, &query_action) >= 0) &&
            (query_action.sa_handler != SIG_DFL) &&
            (query_action.sa_handler != SIG_IGN)) {
            /* A programmer-defined signal handler is in effect. */
            // This might be problematic with multiple commands running at the same time that all define SIGINT
            // ...such as ls.
            // !! this is called from the main thread. So make sure the signal handler does *not* call phtread_exit();
            query_action.sa_handler(SIGINT);
            // kill(getpid(), SIGINT); // infinite loop?
        } else {
            // Send pthread_cancel with the given signal to the current main thread, if there is one.
            if (currentSession->current_command_root_thread != NULL)
                return pthread_cancel(currentSession->current_command_root_thread);
        }
    }
    // No process running
    return ESRCH;
}

extern pthread_t ios_getThreadId(pid_t pid);
int ios_killpid(pid_t pid, int sig) {
    if (ios_getThreadId(pid) > 0) {
        return pthread_kill(ios_getThreadId(pid), sig);
    }
    return 0;
}

void ios_switchSession(const void* sessionId) {
    char* sessionName = (char*) sessionId;
    if ((currentSession != nil) && (parentSession != nil)) {
        if ((currentSession->context == sh_session) && (parentSession->context == sessionName)) {
            // If we are running a sh_session inside the requested sessionId, there is no need to change:
            return;
        }
    }
    
    if ((currentSession != nil) && (currentSession->context != NULL) && (strcmp(currentSession->context, sessionName) == 0)) {
        // Already inside this session: do nothing
        return;
    }

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    id sessionKey = @((NSUInteger)sessionId);
    if (sessionList == nil) {
        sessionList = [NSMutableDictionary new];
        if (currentSession != NULL) [sessionList setObject: [NSValue valueWithPointer:currentSession] forKey: sessionKey];
    }
    currentSession = (sessionParameters*)[[sessionList objectForKey: sessionKey] pointerValue];
    
    if (currentSession == NULL) {
        sessionParameters* newSession =  malloc(sizeof(sessionParameters));
        initSessionParameters(newSession);
        [sessionList setObject: [NSValue valueWithPointer:newSession] forKey: sessionKey];
        currentSession = newSession;
    } else {
        NSString* currentSessionDir = [NSString stringWithCString:currentSession->currentDir encoding:NSUTF8StringEncoding];
        if (![currentSessionDir isEqualToString:[fileManager currentDirectoryPath]]) {
            [fileManager changeCurrentDirectoryPath:currentSessionDir];
        }
        // Da fuck???? Yeah, that would hurt. Why is it there?
        currentSession->stdin = stdin;
        currentSession->stdout = stdout;
        currentSession->stderr = stderr;
    }
}

void ios_setDirectoryURL(NSURL* workingDirectoryURL) {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager changeCurrentDirectoryPath:[workingDirectoryURL path]];
    if (currentSession != NULL) {
        NSString* currentSessionDir = [NSString stringWithCString:currentSession->currentDir encoding:NSUTF8StringEncoding];
        if ([currentSessionDir isEqualToString:[fileManager currentDirectoryPath]]) return;
        strcpy(currentSession->previousDirectory, currentSession->currentDir);
        strcpy(currentSession->currentDir, [[workingDirectoryURL path] UTF8String]);
    }
}

void ios_closeSession(const void* sessionId) {
    // delete information associated with current session:
    if (sessionList == nil) return;
    id sessionKey = @((NSUInteger)sessionId);
    [sessionList removeObjectForKey: sessionKey];
    currentSession = NULL;
}

int ios_isatty(int fd) {
    if (currentSession == NULL) return 0;
    // 2 possibilities: 0, 1, 2 (classical) or fileno(thread_stdout)
    if (thread_stdin != NULL) {
        if ((fd == STDIN_FILENO) || (fd == fileno(currentSession->stdin)) || (fd == fileno(thread_stdin)))
            return (fileno(thread_stdin) == fileno(currentSession->stdin));
    }
    if (thread_stdout != NULL) {
        if ((fd == STDOUT_FILENO) || (fd == fileno(currentSession->stdout)) || (fd == fileno(thread_stdout))) {
            return (fileno(thread_stdout) == fileno(currentSession->stdout));
        }
    }
    if (thread_stderr != NULL) {
        if ((fd == STDERR_FILENO) || (fd == fileno(currentSession->stderr)) || (fd == fileno(thread_stderr)))
            return (fileno(thread_stderr) == fileno(currentSession->stderr));
    }
    return 0;
}

void ios_setStreams(FILE* _stdin, FILE* _stdout, FILE* _stderr) {
    if (currentSession == NULL) return;
    currentSession->stdin = _stdin;
    currentSession->stdout = _stdout;
    currentSession->stderr = _stderr;
}

void ios_settty(FILE* _tty) {
    if (currentSession == NULL) return;
    currentSession->tty = _tty;
}

int ios_gettty(void) {
    if (currentSession == NULL) return -1;
    if (currentSession->tty == NULL) return -1;
    return fileno(currentSession->tty);
}

// Allows commands that are not usually tty-based to get the tty (for password input in ssh/scp/sftp):
int ios_opentty(void) {
    if (currentSession == nil) { return -1; }
    if (currentSession->tty == NULL) return -1;
    currentSession->activePager = true;
    return fileno(currentSession->tty);
}

void ios_closetty(void) {
    if (currentSession == nil) { return; }
    currentSession->activePager = false;
}

int ios_activePager(void) {
    // All commands that read from tty instead of stdin:
    if (currentSession == nil) { return 0; }
    char* currentSessionCommandName;
    if (currentSession->numCommand <= 0)
        currentSessionCommandName = currentSession->commandName[0];
    else
        currentSessionCommandName = currentSession->commandName[currentSession->numCommand - 1];
    if ((strcmp(currentSessionCommandName, "less") == 0) ||
        (strcmp(currentSessionCommandName, "more") == 0)) {
        return 1;
    }
    if (currentSession->activePager) { return 1; }
    return 0;
}

void ios_stopInteractive(void) {
    // Some commands, like sftp, start as "interactive" (they handle all input), then become non-interactive (they let the shell handle input)
    // This could be merged with opentty / closetty above, but stopInteractive involves one more trip to WKWebView->evaluateJS, so it's better not to call it too often.
    void (*function)(void) = NULL;
    function = dlsym(RTLD_MAIN_ONLY, "stopInteractive");
    if (function != NULL) {
        function();
    } else {
        NSLog(@"Could not find function stopInteractive");
    }
}

int ios_storeInteractive(void) {
    // Some commands, like dash, can be started from inside interactive or non-interactive commands. They need to restore the status afterwards.
    int (*function)(void) = NULL;
    function = dlsym(RTLD_MAIN_ONLY, "storeInteractive");
    if (function != NULL) {
        return function();
    } else {
        NSLog(@"Could not find function storeInteractive");
        return 0;
    }
}

void ios_startInteractive(void) {
    // With aliasing, we can have commands that are interactive and not detected by the command-line interpreter.
    void (*function)() = NULL;
    function = dlsym(RTLD_MAIN_ONLY, "startInteractive");
    if (function != NULL) {
        function();
    } else {
        NSLog(@"Could not find function startInteractive");
    }
}

static int isInteractive(const char* command) {
    // let interactiveRegexp = /^vim|^ipython|^less|^more|^ssh|^scp|^sftp|^jump|\|&? *less|\|&? *more|^man|^pico/;
    if (strncmp(command, "vim", 3) == 0) return true;
    if (strncmp(command, "pico", 4) == 0) return true;
    if (strncmp(command, "ipython", 7) == 0) return true;
    if (strncmp(command, "isympy", 6) == 0) return true;
    if (strncmp(command, "less", 4) == 0) return true;
    if (strncmp(command, "more", 4) == 0) return true;
    if (strncmp(command, "ssh", 3) == 0) return true;
    if (strncmp(command, "scp", 3) == 0) return true;
    if (strncmp(command, "man", 3) == 0) return true;
    if (strncmp(command, "sftp", 4) == 0) return true;
    if (strncmp(command, "jump", 4) == 0) return true;
    return false;
}

void ios_setContext(const void *context) {
    if (currentSession == NULL) return;
    currentSession->context = context;
}

void* ios_getContext(void) {
    if (currentSession == NULL) return NULL;
    if (currentSession->context != sh_session)
        return currentSession->context;
    else
        return parentSession->context;
}



// For customization:
// replaces a function  (e.g. ls_main) with another one, provided by the user (ls_mine_main)
// if the function does not exist, add it to the list
// if "allOccurences" is true, search for all commands that share the same function, replace them too.
// ("compress" and "uncompress" both point to compress_main. You probably want to replace both, but maybe
// you just happen to have a very fast uncompress, different from compress).
// We work with function names, not function pointers.
void replaceCommand(NSString* commandName, NSString* functionName, bool allOccurences) {
    // Does that function exist / is reachable? We've had problems with stripping.
    int (*function)(int ac, char** av) = NULL;
    function = dlsym(RTLD_MAIN_ONLY, functionName.UTF8String);
    if (!function) {
        NSLog(@"replaceCommand: %@ does not exist", functionName);
        return; // if not, we don't replace.
    }
    if (commandList == nil) initializeCommandList();
    NSArray* oldValues = [commandList objectForKey: commandName];
    NSString* oldFunctionName = nil;
    if (oldValues != nil) oldFunctionName = oldValues[1];
    NSMutableDictionary *mutableDict = [commandList mutableCopy];
    mutableDict[commandName] = [NSArray arrayWithObjects: @"MAIN", functionName, @"", @"file", nil];
    
    if ((oldFunctionName != nil) && allOccurences) {
        // scan through all dictionary entries
        for (NSString* existingCommand in mutableDict.allKeys) {
            NSArray* currentPosition = [mutableDict objectForKey: existingCommand];
            if ([currentPosition[1] isEqualToString:oldFunctionName])
                [mutableDict setValue: [NSArray arrayWithObjects: @"MAIN", functionName, @"", @"file", nil] forKey: existingCommand];
        }
    }
    commandList = [mutableDict copy]; // back to non-mutable version
}

// For customization:
// Add an entire plist file defining multiple commands. Commands follow the same syntax as initializeCommandList:
//
// key = command name, followed by an array of 4 components:
// 1st component: name of digital library (can be "MAIN" if command is defined inside program)
// 2nd component: name of function to be called
// 3rd component: chain sent to getopt (for arguments in autocomplete)
// 4th component: takes a file/directory as argument
//
// Example:
//    <key>rlogin</key>
// <array>
// <string>libnetwork_ios.dylib</string>
// <string>rlogin_main</string>
// <string>468EKLNS:X:acde:fFk:l:n:rs:uxy</string>
// <string>no</string>
// </array>
NSError* addCommandList(NSString* fileLocation) {
    if (commandList == nil) initializeCommandList();
    NSError* error;
    
    NSURL *locationURL = [NSURL fileURLWithPath:fileLocation isDirectory:NO];
    if ([locationURL checkResourceIsReachableAndReturnError:&error] == NO) {
        fprintf(stderr, "Resource dictionary %s not found", fileLocation.UTF8String);
        return error;
    }

    NSData* dataLoadedFromFile = [NSData dataWithContentsOfFile:fileLocation  options:0 error:&error];
    if (!dataLoadedFromFile) return error;
    NSDictionary* newCommandList = [NSPropertyListSerialization propertyListWithData:dataLoadedFromFile options:NSPropertyListImmutable format:NULL error:&error];
    if (!newCommandList) return error;
    // merge the two dictionaries:
    NSMutableDictionary *mutableDict = [commandList mutableCopy];
    [mutableDict addEntriesFromDictionary:newCommandList];
    commandList = [mutableDict copy];
    return NULL;
}


NSString* commandsAsString(void) {
    
    if (commandList == nil) initializeCommandList();
    
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:commandList.allKeys options:0 error:&err];
    NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return myString;
}

NSArray* commandsAsArray(void) {
    if (commandList == nil) initializeCommandList();
    return commandList.allKeys;
}

// for output file names, arguments: returns a pointer to
// immediately after the end of the argument, or NULL.
// Method:
//   - if argument begins with ", go to next unescaped "
//   - if argument begins with ', go to next unescaped '
//   - otherwise, move to next unescaped space
//
// Must be combined with another function to remove backslash.

// Aux function:
static void* nextUnescapedCharacter(const char* str, const char c) {
    char* nextOccurence = strchr(str, c);
    while (nextOccurence != NULL) {
        if ((nextOccurence > str + 1) && (*(nextOccurence - 1) == '\\')) {
            // There is a backlash before the character.
            int numBackslash = 0;
            char* countBack = nextOccurence - 1;
            while ((countBack > str) && (*countBack == '\\')) { numBackslash++; countBack--; }
            if (numBackslash % 2 == 0) return nextOccurence; // even number of backslash
        } else return nextOccurence;
        nextOccurence = strchr(nextOccurence + 1, c);
    }
    return nextOccurence;
}

static char* getLastCharacterOfArgument(const char* argument) {
    // Problem: perl -e 'install([ from_to => {@ARGV}, verbose => '\''0'\'', uninstall_shadows => '\''0'\'', dir_mode => '\''755'\'' ]);'
    // Should become: "perl", "-e", "install([ from_to => {@ARGV}, verbose => '0', uninstall_shadows => '0', dir_mode => '755' ]);"
    // If there is no space after the end quote, keep concatenating the argument.
    char recordSeparator = 0x1e;
    if (strlen(argument) == 0) return NULL; // be safe
    if (argument[0] == '"') {
        char* endquote = nextUnescapedCharacter(argument + 1, '"');
        if (endquote != NULL) {
            // Is there a space after the endquote?
            if (strlen(endquote) <= 1) { return endquote + 1; } // last character
            if (endquote[1] == ' ') { return endquote + 1; } // space after endquote, we're good
            if (strncmp(endquote, "\"\\\"\"", 3) == 0 ) {
                // Perl (for example) wrote here: "\"" and if the substitution works we get " inside the argument
                // We rewrite the argument here (it gets shorter):
                char* write = endquote;
                for (char* read = endquote + 3; *read != 0; read++, write++) {
                    *write = *read;
                }
                write[0] = 0;
                return getLastCharacterOfArgument(endquote + 1);
            }
            // After quote non space character, we should continue till space:
            // `ssh "user name"@localhost`
            return nextUnescapedCharacter(endquote + 1, ' ');
        }
        return NULL;
    } else if (argument[0] == '\'') {
        char* endquote = nextUnescapedCharacter(argument + 1, '\'');
        if (endquote != NULL) {
            // Is there a space after the endquote?
            if (strlen(endquote) <= 1) { return endquote + 1; } // last character
            if (endquote[1] == ' ') { return endquote + 1; } // space after endquote, we're good
            if (strncmp(endquote, "'\\''", 3) == 0 ) {
                // Perl (for example) wrote here: '\'' and if the substitution works we get ' inside the argument
                // We rewrite the argument here (it gets shorter):
                // /!\ There could be other cases, e.g. '"', but why would they do that?
                char* write = endquote;
                for (char* read = endquote + 3; *read != 0; read++, write++) {
                    *write = *read;
                }
                write[0] = 0;
                return getLastCharacterOfArgument(endquote);
            }
            // After quote non space character, we should continue till space
            // `ssh "user name"@localhost`
            return nextUnescapedCharacter(endquote + 1, ' ');
        }
        return NULL;
    } else if (argument[0] == recordSeparator) {
        char* endquote = strchr(argument + 1, recordSeparator);
        if (endquote == NULL) return NULL; // be safe (see #153)
        return endquote + 1;
    }
    // TODO: the last character of the argument could also be '<' or '>' (vim does that, with no space after file name)
    else return nextUnescapedCharacter(argument + 1, ' ');
}

// remove quotes at the beginning of argument if there's a balancing one at the end
static char* unquoteArgument(char* argument) {
    if (argument[0] == '"') {
        if (argument[strlen(argument) - 1] == '"') {
            argument[strlen(argument) - 1] = 0x0;
            return argument + 1;
        }
    }
    if (argument[0] == '\'') {
        if (argument[strlen(argument) - 1] == '\'') {
            argument[strlen(argument) - 1] = 0x0;
            return argument + 1;
        }
    }
    char recordSeparator = 0x1e;
    if (argument[0] == recordSeparator) {
        if (argument[strlen(argument) - 1] == recordSeparator) {
            argument[strlen(argument) - 1] = 0x0;
            return argument + 1;
        }
    }
    // no quotes at the beginning: replace all escaped characters:
    // '\x' -> x
    char* nextOccurence = strchr(argument, '\\');
    while ((nextOccurence != NULL) && (strlen(nextOccurence) > 0)) {
        memmove(nextOccurence, nextOccurence + 1, strlen(nextOccurence + 1) + 1);
        // strcpy(nextOccurence, nextOccurence + 1);
        nextOccurence = strchr(nextOccurence + 1, '\\');
    }
    return argument;
}


static int isRealCommand(const char* fileName) {
    // File exists, is executable, not a directory.
    // We check whether: a) its size is > 0 and b) it is not a Mach-O binary
    int returnValue = false;
    struct stat sb;
    if (stat(fileName, &sb) == 0) {
        // We can have an empty file with the same name in the path, to fool which():
        if (sb.st_size == 0) {
            return false;
        }
        // Not an empty file, so let's check its magic number:
        int fd = open(fileName, O_RDONLY);
        if (fd > 0) {
            char res[4];
            ssize_t retval = read(fd, &res, 4);
            if (retval == 4) {
                // MH_MAGIC_64 = 0xfeedfacf
                if ((res[0] != '\xcf') || (res[1] != '\xfa') || (res[2] != '\xed') || (res[3] != '\xfe')) {
                    // it's not a Mach-O binary:
                    returnValue = true;
                }
            }
            close (fd);
        }
    }
    return returnValue;
}

static bool isBackgroundCommand(char* command) {
    if (backgroundCommandList == nil) {
        return false;
    }
    if (command == NULL) {
        return false;
    }
    NSString *commandAsString = [NSString stringWithUTF8String: command];
    for (NSString* commandInList in backgroundCommandList) {
        if ([commandInList isEqualToString: commandAsString]) {
            // NSLog(@"%s is a backgroundCommand\n", command);
            return true;
        }
        if ([commandInList hasSuffix:@"*"]) {
            NSString* shortCommand = commandInList;
            shortCommand = [shortCommand substringToIndex:[shortCommand length] - 1];
            while ([shortCommand hasSuffix:@" "]) {
                shortCommand = [shortCommand substringToIndex:[shortCommand length] - 1];
            }
            if ([commandAsString hasPrefix: shortCommand]) {
                // NSLog(@"%s is a backgroundCommand\n", command);
                return true;
            }
        }
    }
    return false;
}

NSString* beforeScriptCommandName(NSString* scriptName) {
    // scans the PATH for a binary that has the name script and non-null size,
    // checks whether it has wasm signature, if so insert "wasm" before script name.
    BOOL isDir = false;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    directoriesInPath = [fullCommandPath componentsSeparatedByString:@":"];
    for (NSString* path in directoriesInPath) {
        // If we don't have access to the path component, there's no point in continuing:
        if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) continue;
        if (!isDir) continue; // same in the (unlikely) event the path component is not a directory
        NSString* locationName;
        // search for 2 possibilities: name and name.wasm
        locationName = [path stringByAppendingPathComponent:scriptName];
        bool fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
        fileFound = fileFound && !isDir;
        if (!fileFound) {
            locationName = [[path stringByAppendingPathComponent:scriptName] stringByAppendingString:@".wasm"];
            fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
            fileFound = fileFound && !isDir;
        }
        if (!fileFound) continue;
        // isExecutableFileAtPath replies "NO" even if file has x-bit set.
        // if (![fileManager  isExecutableFileAtPath:cmdname]) continue;
        struct stat sb;
        // Files inside the Application Bundle will always have "x" removed. Don't check.
        if (!([path containsString: [[NSBundle mainBundle] resourcePath]]) // Not inside the App Bundle
            && !((stat(locationName.UTF8String, &sb) == 0))) // file exists, is not a directory
            continue;
        // At this point the file exists, is a file.
        if (!isRealCommand(locationName.UTF8String)) // if it's one of our fake commands, search is over.
            return NULL;
        NSData *data = [NSData dataWithContentsOfFile:locationName]; // You have the data. Conversion to String probably failed.
        NSString *fileContent = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        if ((fileContent == nil) && (data.length > 0)) {
            // Conversion to string failed with UTF8. Try with Ascii as a backup:
            fileContent =  [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
        }
        NSString* signature;
        // Detect WebAssembly file signature: '\0asm' (begins with 0, so not a string)
        if ((data.length >0) && (((char*)data.bytes)[0] == 0)) {
            // fileContent = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
            NSRange signatureRange = NSMakeRange(1, 3);
            signature = [fileContent substringWithRange:signatureRange];
        }
        if ([signature isEqualToString:@"asm"]) {
            return [@"wasm " stringByAppendingString:locationName];
        }
    }
    // We didn't find anything, no change to scriptName
    return NULL;
}



int ios_system(const char* inputCmd) {
    NSLog(@"command= %s pid= %d\n", inputCmd, ios_currentPid());

    char* command;
    // The names of the files for stdin, stdout, stderr
    char* inputFileName = 0;
    char* outputFileName = 0;
    char* errorFileName = 0;
    // Where the symbols "<", ">" or "2>" were.
    // to be replaced by 0x0 later.
    char* outputFileMarker = 0;
    char* inputFileMarker = 0;
    char* errorFileMarker = 0;
    char* scriptName = 0; // interpreted commands
    bool  sharedErrorOutput = false;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    // NSLog(@"ios_system, stdout %d \n", thread_stdout == NULL ? 0 : fileno(thread_stdout));
    // NSLog(@"ios_system, stderr %d \n", thread_stderr == NULL ? 0 : fileno(thread_stderr));
    if (currentSession == NULL) {
        currentSession = malloc(sizeof(sessionParameters));
        initSessionParameters(currentSession);
    }
    currentSession->global_errno = 0;
    NSLog(@"Starting command: %s currentSession->isMainThread: %d", inputCmd, currentSession->isMainThread);
    // Don't start if the command is NULL:
    if (inputCmd == NULL) {
        ios_storeThreadId(0);
        return 0;
    }

    // initialize:
    if (thread_stdin == 0) thread_stdin = currentSession->stdin;
    if (thread_stdout == 0) thread_stdout = currentSession->stdout;
    if (thread_stderr == 0) thread_stderr = currentSession->stderr;
    if (thread_context == 0) thread_context = currentSession->context;

    char* cmd = strdup(inputCmd);
    char* maxPointer = cmd + strlen(cmd);
    char* originalCommand = cmd;
    // fprintf(thread_stderr, "Command sent: %s \n", cmd); fflush(stderr);
    if (cmd[0] == '"') {
        // Command was enclosed in quotes (almost always with Vim)
        // It can also be the executable enclose in quotes
        char* endCmd = strstr(cmd + 1, "\""); // find closing quote
        if (endCmd) {
            cmd = cmd + 1; // remove starting quote
            endCmd[0] = ' ';
            assert(endCmd < maxPointer);
        }
        // assert(cmd + strlen(cmd) < maxPointer);
    }
    if (cmd[0] == '(') {
        // Standard vim encoding: command between parentheses
        command = cmd + 1;
        char* endCmd = strstrquoted(command, ")"); // remove closing parenthesis
        if (endCmd) {
            endCmd[0] = ' ';
            assert(endCmd < maxPointer);
            // inputFileMarker = endCmd + 1;
        }
    } else command = cmd;
    // fprintf(thread_stderr, "Command sent: %s \n", command);
    // Environment variables before alias expansion:
    char* commandForParsing = strdup(command);
    char* commandForParsingFree = commandForParsing;
    char* firstSpace = strstrquoted(commandForParsing, " ");
    while (firstSpace != NULL) {
        *firstSpace = 0;
        char* equalSign = strchr(commandForParsing, '=');
        if (equalSign == NULL) break;
        *equalSign = 0;
        ios_setenv(commandForParsing, equalSign+1, 1);
        command += (firstSpace - commandForParsing) + 1;
        commandForParsing = firstSpace + 1;
        firstSpace = strstrquoted(commandForParsing, " ");
    }
    free(commandForParsingFree);
    // alias expansion *before* input, output and error redirection.
    if ((command[0] != '\\') && (aliasDictionary != nil)) {
        // \command = cancel aliasing, get the original command
        char* commandForParsing = strdup(command);
        char* firstSpace = strstrquoted(commandForParsing, " ");
        if (firstSpace != NULL) { *firstSpace = 0; }
        NSString* commandAsString = [NSString stringWithCString:commandForParsing encoding:NSUTF8StringEncoding];
        NSArray<NSString*>* aliasedCommand = aliasDictionary[commandAsString];
        if (aliasedCommand != nil) {
            NSLog(@"%s %s %s", aliasedCommand[0].UTF8String, aliasedCommand[1].UTF8String, aliasedCommand[2].UTF8String);
            char* newCommand = NULL;
            if (aliasedCommand[2].length == 0) {
                // all the alias, then all the arguments:
                if (firstSpace == NULL) {
                    newCommand = strdup(aliasedCommand[0].UTF8String);
                } else {
                    unsigned long newCommandLength = aliasedCommand[0].length + 2 + strlen(firstSpace+1);
                    // + 2: 1 for space, 1 for NULL termination
                    newCommand = malloc(newCommandLength * sizeof(char));
                    sprintf(newCommand, "%s %s", aliasedCommand[0].UTF8String, firstSpace+1);
                }
            } else if ([aliasedCommand[2] isEqualToString: @"afterLast"]) {
                unsigned long newCommandLength = aliasedCommand[0].length + 2 + aliasedCommand[1].length;
                // + 2: 1 for space, 1 for NULL termination
                if (firstSpace == NULL) { // no arguments
                    newCommand = malloc(newCommandLength * sizeof(char));
                    sprintf(newCommand, "%s %s", aliasedCommand[0].UTF8String, aliasedCommand[1].UTF8String);
                } else {
                    newCommandLength += strlen(firstSpace+1) + 1; // 1 more space
                    newCommand = malloc(newCommandLength * sizeof(char));
                    sprintf(newCommand, "%s %s %s", aliasedCommand[0].UTF8String, firstSpace+1, aliasedCommand[1].UTF8String);
                }
            } else if ([aliasedCommand[2] isEqualToString: @"afterFirst"]) {
                unsigned long newCommandLength = aliasedCommand[0].length + 2 + aliasedCommand[1].length;
                // + 2: 1 for space, 1 for NULL termination
                if (firstSpace == NULL) { // no arguments
                    newCommand = malloc(newCommandLength * sizeof(char));
                    sprintf(newCommand, "%s %s", aliasedCommand[0].UTF8String, aliasedCommand[1].UTF8String);
                } else {
                    char* arguments = firstSpace + 1;
                    char* secondSpace = strstrquoted(arguments, " ");
                    if (secondSpace == NULL) {
                        // only 1 argument, nothing after that:
                        newCommandLength += strlen(arguments) + 1; // 1 more space
                        newCommand = malloc(newCommandLength * sizeof(char));
                        sprintf(newCommand, "%s %s %s", aliasedCommand[0].UTF8String, arguments, aliasedCommand[1].UTF8String);
                    } else {
                        *secondSpace = 0;
                        char* otherArguments = secondSpace + 1;
                        newCommandLength += strlen(arguments) + strlen(otherArguments) + 2; // 2 more spaces
                        newCommand = malloc(newCommandLength * sizeof(char));
                        sprintf(newCommand, "%s %s %s %s", aliasedCommand[0].UTF8String, arguments, aliasedCommand[1].UTF8String, otherArguments);
                    }
                }
            }
            if (newCommand != NULL) {
                free(originalCommand);
                // After alias expansion, the new command replaces the old one:
                originalCommand = newCommand;
                cmd = newCommand;
                command = newCommand;
            }
        }
        free(commandForParsing);
    }
    // Maybe we aliased to an interactive command (vim, ssh, less, more, man, scp, sftp)
    // We need to tell the command line editor:
    if (isInteractive(command)) {
        ios_startInteractive();
    }
    // NSLog(@"command after alias expansion= %s\n", command);
    // Search for input, output and error redirection
    // They can be in any order, although the usual are:
    // command < input > output 2> error, command < input > output 2>&1 or command < input >& output
    // The last two are equivalent. Vim prefers the second.
    // Search for input file "< " and output file " >"
    if (!inputFileMarker) inputFileMarker = command;
    outputFileMarker = inputFileMarker;
    functionParameters *params = (functionParameters*) malloc(sizeof(functionParameters));
    // If child_streams have been defined (in dup2 or popen), the new thread takes them.
    params->stdin = child_stdin;
    params->stdout = child_stdout;
    params->stderr = child_stderr;
    params->session = currentSession;
    params->backgroundCommand = isBackgroundCommand(command);
    params->numInterpreter = 0;

    params->context = thread_context;
  
    child_stdin = child_stdout = child_stderr = NULL;
    params->argc = 0; params->argv = 0; params->argv_ref = 0;
    params->function = NULL; params->isPipeOut = false; params->isPipeErr = false;
    // Only scan for input / output if there is no argument marker
    char recordSeparator = 0x1e;
    char* recordSeparatorPosition = strchr(inputFileMarker, recordSeparator);
    if (recordSeparatorPosition == NULL) {
        // scan until first "<" (input file)
        inputFileMarker = strstrquoted(inputFileMarker, "<");
        // scan until first non-space character:
        if (inputFileMarker) {
            if ((strlen(inputFileMarker) > 1) && (inputFileMarker[1] == '=')) {
                // >= (used by pip install, e.g. "setuptools<=56"
                // This is very specific. pip needs it, other commands act differently.
                char* doubleDashMarker = strstrquoted(command, " -- ");
                // Is there a double dash before the ">="? If not keep going.
                if (!doubleDashMarker || (doubleDashMarker > inputFileMarker)) {
                    inputFileName = inputFileMarker + 1; // skip past '<'
                }
            } else {
                inputFileName = inputFileMarker + 1; // skip past '<'
            }
            if (inputFileName) {
                // skip past all spaces
                while ((inputFileName[0] == ' ') && strlen(inputFileName) > 0) inputFileName++;
            }
        }
        // is there a pipe ("|", "&|" or "|&")
        // We assume here a logical command order: < before pipe, pipe before >.
        // TODO: check what happens for unlogical commands. Refuse them, but gently.
        // TODO: implement tee, because that has been removed
        char* pipeMarker = strstrquoted(outputFileMarker,"&|");
        if (!pipeMarker) pipeMarker = strstrquoted(outputFileMarker,"|&"); // both seem to work
        if (pipeMarker) {
            bool pushMainThread = currentSession->isMainThread;
            currentSession->isMainThread = false;
            if (params->stdout != 0) thread_stdout = params->stdout;
            if (params->stderr != 0) thread_stderr = params->stderr;
            // if popen fails, don't start the command
            params->stdout = ios_popen(pipeMarker+2, "w");
            params->stderr = params->stdout;
            currentSession->isMainThread = pushMainThread;
            pipeMarker[0] = 0x0;
            sharedErrorOutput = true;
            if (params->stdout == NULL) { // pipe open failed, return before we start a command
                NSLog(@"Failed launching pipe for %s\n", pipeMarker+2);
                ios_storeThreadId(0);
                free(params);
                free(originalCommand); // releases cmd, which was a strdup of inputCommand
                return currentSession->global_errno;
            }
        } else {
            pipeMarker = strstrquoted(outputFileMarker,"|");
            if (pipeMarker) {
                bool pushMainThread = currentSession->isMainThread;
                currentSession->isMainThread = false;
                if (params->stdout != 0) thread_stdout = params->stdout;
                if (params->stderr != 0) thread_stderr = params->stderr; // ?????
                // if popen fails, don't start the command
                params->stdout = ios_popen(pipeMarker+1, "w");
                currentSession->isMainThread = pushMainThread;
                pipeMarker[0] = 0x0;
                if (params->stdout == NULL) { // pipe open failed, return before we start a command
                    NSLog(@"Failed launching pipe for %s\n", pipeMarker+1);
                    ios_storeThreadId(0);
                    free(params);
                    free(originalCommand); // releases cmd, which was a strdup of inputCommand
                    return currentSession->global_errno;
                }
            }
        }
        // We have removed the pipe part. Still need to parse the rest of the command
        // Must scan in strstr by reverse order of inclusion. So "2>&1" before "2>" before ">"
        errorFileMarker = strstrquoted(outputFileMarker,"&>"); // both stderr/stdout sent to same file
        // output file name will be after "&>"
        if (errorFileMarker) { outputFileName = errorFileMarker + 2; outputFileMarker = errorFileMarker; }
        if (!errorFileMarker) {
            // TODO: 2>&1 before > means redirect stderr to (current) stdout, then redirects stdout
            // ...except with a pipe.
            // Currently, we don't check for that.
            errorFileMarker = strstrquoted(outputFileMarker,"2>&1"); // both stderr/stdout sent to same file
            if (errorFileMarker) {
                outputFileName = NULL;
                if (params->stdout) params->stderr = params->stdout;
                outputFileMarker = strstrquoted(outputFileMarker, ">");
                if (outputFileMarker - errorFileMarker == 1) // the first '>' was the one from '2>&1'
                    outputFileMarker = strstrquoted(outputFileMarker + 2, ">"); // is there one after that?
                if (outputFileMarker)
                    outputFileName = outputFileMarker + 1; // skip past '>'
            }
        }
        if (errorFileMarker) { sharedErrorOutput = true; }
        else {
            // specific name for error file?
            errorFileMarker = strstrquoted(outputFileMarker,"2>");
            if (errorFileMarker) {
                errorFileName = errorFileMarker + 2; // skip past "2>"
                // skip past all spaces:
                while ((errorFileName[0] == ' ') && strlen(errorFileName) > 0) errorFileName++;
            }
        }
        // scan until first ">"
        bool appendToFileName = false;
        if (!sharedErrorOutput) {
            // output and append.
            outputFileMarker = strstrquoted(outputFileMarker, ">");
            if (outputFileMarker) {
                if ((strlen(outputFileMarker) > 1) && (outputFileMarker[1] == '>')) { // >>
                    outputFileName = outputFileMarker + 2; // skip past ">>"
                    appendToFileName = true;
                } else if ((strlen(outputFileMarker) > 1) && (outputFileMarker[1] == '=')) {
                    // >= (used by pip install, e.g. "setuptools>=56,!=61.0.0"
                    // This is very specific. pip needs it, other commands act differently.
                    char* doubleDashMarker = strstrquoted(command, " -- ");
                    // Is there a double dash before the ">="? If not keep going.
                    if (!doubleDashMarker || (doubleDashMarker > outputFileMarker)) {
                        outputFileName = outputFileMarker + 1; // skip past '>'
                    } // Otherwise do nothing
                } else {
                    outputFileName = outputFileMarker + 1; // skip past '>'
                }
            }
        } else {
            if (outputFileName == NULL)
                outputFileMarker = NULL;
        }
        if (outputFileName) {
            while ((outputFileName[0] == ' ') && strlen(outputFileName) > 0) outputFileName++;
        }
        if (errorFileName && (outputFileName == errorFileName)) {
            // we got the same ">" twice, pick the next one ("2>" was before ">")
            outputFileMarker = errorFileName;
            outputFileMarker = strstrquoted(outputFileMarker, ">");
            if (outputFileMarker) {
                if ((strlen(outputFileMarker) > 1) && (outputFileMarker[1] == '>')) { // >>
                    outputFileName = outputFileMarker + 2; // skip past ">>"
                    appendToFileName = true;
                } else {
                    outputFileName = outputFileMarker + 1; // skip past '>'
                }
                while ((outputFileName[0] == ' ') && strlen(outputFileName) > 0) outputFileName++;
            } else outputFileName = NULL; // Only "2>", but no ">". It happens.
        }
        if (outputFileName) {
            char* endFile = getLastCharacterOfArgument(outputFileName);
            if (endFile) endFile[0] = 0x00; // end output file name at first space
            assert(endFile <= maxPointer);
        }
        if (inputFileName) {
            char* endFile = getLastCharacterOfArgument(inputFileName);
            if (endFile) endFile[0] = 0x00; // end input file name at first space
            assert(endFile <= maxPointer);
        }
        if (errorFileName) {
            char* endFile = getLastCharacterOfArgument(errorFileName);
            if (endFile) endFile[0] = 0x00; // end error file name at first space
            assert(endFile <= maxPointer);
        }
        // insert chain termination elements at the beginning of each filename.
        // Must be done after the parsing.
        if (inputFileMarker) inputFileMarker[0] = 0x0;
        // There was a test " && (params->stdout == NULL)" below. Why?
        if (outputFileMarker) outputFileMarker[0] = 0x0; // There
        if (errorFileMarker) errorFileMarker[0] = 0x0;
        // strip filenames of quotes, if any:
        if (outputFileName) outputFileName = unquoteArgument(outputFileName);
        if (inputFileName) inputFileName = unquoteArgument(inputFileName);
        if (errorFileName) errorFileName = unquoteArgument(errorFileName);
        //
        FILE* newStream;
        if (inputFileName) {
            newStream = fopen(ios_expandFilename(inputFileName), "r");
            if (newStream) params->stdin = newStream;
        }
        if (params->stdin == NULL) params->stdin = thread_stdin;
        if (outputFileName) {
            if (appendToFileName) {
                newStream = fopen(ios_expandFilename(outputFileName), "a"); // append
            } else {
                newStream = fopen(ios_expandFilename(outputFileName), "w");
            }
            NSLog(@"Opened %s as output file: %x", outputFileName, newStream);
            if (newStream) {
                if (params->stdout != NULL) {
                    if (fileno(params->stdout) != fileno(currentSession->stdout)) fclose(params->stdout);
                }
                params->stdout = newStream;
            }
        }
        if (params->stdout == NULL) params->stdout = thread_stdout;
        if (sharedErrorOutput && (params->stderr != params->stdout)) {
            if (params->stderr != NULL) {
                if (fileno(params->stderr) != fileno(currentSession->stderr)) fclose(params->stderr);
            }
            params->stderr = params->stdout;
        }
        else if (errorFileName) {
            newStream = NULL;
            newStream = fopen(ios_expandFilename(errorFileName), "w");
            if (newStream) {
                if (params->stderr != NULL) {
                    if (fileno(params->stderr) != fileno(currentSession->stderr)) fclose(params->stderr);
                }
                params->stderr = newStream;
            }
        }
        if (params->stderr == NULL) params->stderr = thread_stderr;
    } // recordSeparator != NULL
    if (params->stdin == NULL) params->stdin = thread_stdin;
    if (params->stdout == NULL) params->stdout = thread_stdout;
    if (params->stderr == NULL) params->stderr = thread_stderr;
    int argc = 0;
    size_t numSpaces = 0;
    // the number of arguments is *at most* the number of spaces plus one
    char* str = command;
    while(*str) if (*str++ == ' ') ++numSpaces;
    char** argv = (char **)malloc(sizeof(char*) * (numSpaces + 2));
    bool* dontExpand = malloc(sizeof(bool) * (numSpaces + 2));
    // n spaces = n+1 arguments, plus null at the end
    str = command;
    while (*str) {
        argv[argc] = str;
        dontExpand[argc] = false;
        argc += 1;
        if ((argc == 2) && (strcmp(argv[0], "export") == 0)) break; // don't try to unquote the argument of export.
        char* end = getLastCharacterOfArgument(str);
        bool mustBreak = (end == NULL) || (strlen(end) == 0);
        if (!mustBreak) end[0] = 0x0;
        if ((str[0] == '\'') || (str[0] == '"') || (str[0] == recordSeparator)) {
            dontExpand[argc-1] = true; // don't expand arguments in quotes
        }
        argv[argc-1] = unquoteArgument(argv[argc-1]);
        if (mustBreak) break;
        str = end + 1;
        assert(argc < numSpaces + 2);
        while (str && (str[0] == ' ')) str++; // skip multiple spaces
    }
    argv[argc] = NULL;
    if (argc != 0) {
        // So far, all arguments are pointers into originalCommand.
        // We need to change them (environment variables expansion, ~ expansion, etc)
        // Duplicate everything so we can realloc:
        char** argv_copy = (char **)malloc(sizeof(char*) * (argc + 1));
        for (int i = 0; i < argc; i++) argv_copy[i] = strdup(argv[i]);
        argv_copy[argc] = NULL;
        free(argv);
        argv = argv_copy;
        // We have the arguments. Parse them for environment variables, ~, etc.
        for (int i = 1; i < argc; i++) if (!dontExpand[i]) {  argv[i] = parseArgument(argv[i], argv[0]); }
        // wildcard expansion (*, ?, []...) Has to be after $ and ~ expansion, results in larger arguments
        for (int i = 1; i < argc; i++) if (!dontExpand[i]) {
            if (strstrquoted (argv[i],"*") || strstrquoted (argv[i],"?") || strstrquoted (argv[i],"[")) {
                glob_t gt;
                if (glob(argv[i], 0, NULL, &gt) == 0) {
                    argc += gt.gl_matchc - 1;
                    argv = (char **)realloc(argv, sizeof(char*) * (argc + 1));
                    dontExpand = (bool *)realloc(dontExpand, sizeof(bool) * (argc + 1));
                    // Move everything after i by gt.gl_matchc - 1 steps up:
                    for (int j = argc; j - gt.gl_matchc + 1 > i; j--) {
                        argv[j] = argv[j - gt.gl_matchc + 1];
                        dontExpand[j] = dontExpand[j - gt.gl_matchc + 1];
                    }   
                    for (int j = 0; j < gt.gl_matchc; j++) {
                        argv[i + j] = strdup(gt.gl_pathv[j]);
                    }
                    i += gt.gl_matchc - 1;
                    globfree(&gt);
                } else {
                    // If there is no match, leave parameter as is, continue with command.
                    // Not exactly Unix behaviour, but more convenient on Phones.
                    // fprintf(params->stderr, "%s: %s: No match\n", argv[0], argv[i]);
                    // fflush(params->stderr);
                    globfree(&gt);
                }
            }
        }
        free(dontExpand);
        // Now call the actual command:
        // - is argv[0] a command that refers to a file? (either absolute path, or in $PATH)
        //   if so, does it exist, does it have +x bit set, does it have #! python or #! lua on the first line?
        //   if yes to all, call the relevant interpreter. Works for hg, for example.
        if (argv[0][0] == '\\') {
            // Just remove the \ at the beginning
            // There can be several versions of a command (e.g. ls as precompiled and ls written in Python)
            // The executable file has precedence, unless the user has specified they want the original
            // version, by prefixing it with \. So "\ls" == always "our" ls. "ls" == maybe ~/Library/bin/ls
            // (if it exists).
            // It also cancels aliases.
            size_t len_with_terminator = strlen(argv[0] + 1) + 1;
            memmove(argv[0], argv[0] + 1, len_with_terminator);
        } else  {
            NSString* commandName = [NSString stringWithCString:argv[0]  encoding:NSUTF8StringEncoding];
            // strcpy(currentSession->commandName, argv[0]);
            // store into heap:
            if ((currentSession->numCommand <= 0) && (strlen(currentSession->commandName[0]) == 0)) {
                strcpy(currentSession->commandName[0], argv[0]);
                currentSession->numCommand = 1;
            } else {
                if (currentSession->numCommand >= currentSession->numCommandsAllocated) {
                    int oldCommandsAllocated = currentSession->numCommandsAllocated;
                    currentSession->numCommandsAllocated += 10;
                    currentSession->commandName = realloc(currentSession->commandName, sizeof(char*) * currentSession->numCommandsAllocated);
                    for (int i = oldCommandsAllocated; i < currentSession->numCommandsAllocated; i++) {
                        currentSession->commandName[i] = malloc(sizeof(char) * NAME_MAX);
                    }
                }
                strcpy(currentSession->commandName[currentSession->numCommand], argv[0]);
                currentSession->numCommand += 1;
            }
            BOOL isDir = false;
            bool cmdIsAFile = false;
            bool cmdIsReal = false;
            bool cmdIsAPath = false;
            if ([commandName hasPrefix:@"~/"]) {
                NSString* replacement_string = [NSString stringWithCString:(getenv("HOME")) encoding:NSUTF8StringEncoding];
                NSString* test_string = @"~";
                commandName = [commandName stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange(0, 1)];
            }
            if ([fileManager fileExistsAtPath:commandName isDirectory:&isDir]  && (!isDir)) {
                // File exists, is a file.
                struct stat sb;
                if (stat(commandName.UTF8String, &sb) == 0) {
                    // File exists, is executable, not a directory.
                    cmdIsAFile = true;
                    // We can have an empty file with the same name in the path, to fool which():
                    // We can also have a Mach-O binary with the same name in the path (in simulator, mostly)
                    cmdIsReal = isRealCommand(commandName.UTF8String);
                }
            }
            // if commandName contains "/", then it's a path, and we don't search for it in PATH.
            cmdIsAPath = ([commandName rangeOfString:@"/"].location != NSNotFound);
            if (!cmdIsAPath || cmdIsAFile) {
                // We go through the path, because that command may be a file in the path
                NSString* checkingPath = [NSString stringWithCString:getenv("PATH") encoding:NSUTF8StringEncoding];
                if (! [fullCommandPath isEqualToString:checkingPath]) {
                    fullCommandPath = checkingPath;
                    directoriesInPath = [fullCommandPath componentsSeparatedByString:@":"];
                }
                for (NSString* path in directoriesInPath) {
                    // If we don't have access to the path component, there's no point in continuing:
                    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) continue;
                    if (!isDir) continue; // same in the (unlikely) event the path component is not a directory
                    NSString* locationName;
                    if (!cmdIsAFile) {
                        // search for 4 possibilities: name, name.bc, name.ll and name.wasm
                        locationName = [path stringByAppendingPathComponent:commandName];
                        bool fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
                        fileFound = fileFound && !isDir;
                        if (!fileFound) {
                            locationName = [[path stringByAppendingPathComponent:commandName] stringByAppendingString:@".bc"];
                            fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
                            fileFound = fileFound && !isDir;
                        }
                        if (!fileFound) {
                            locationName = [[path stringByAppendingPathComponent:commandName] stringByAppendingString:@".ll"];
                            fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
                            fileFound = fileFound && !isDir;
                        }
                        if (!fileFound) {
                            locationName = [[path stringByAppendingPathComponent:commandName] stringByAppendingString:@".wasm"];
                            fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
                            fileFound = fileFound && !isDir;
                        }
                        if (!fileFound) continue;
                        // isExecutableFileAtPath replies "NO" even if file has x-bit set.
                        // if (![fileManager  isExecutableFileAtPath:cmdname]) continue;
                        struct stat sb;
                        // Files inside the Application Bundle will always have "x" removed. Don't check.
                        if (!([path containsString: [[NSBundle mainBundle] resourcePath]]) // Not inside the App Bundle
                            && !((stat(locationName.UTF8String, &sb) == 0))) // file exists, is not a directory
                            continue;
                    } else
                        // if (cmdIsAFile) we are now ready to execute this file:
                        locationName = commandName;
                    if (([locationName hasSuffix:@".bc"]) || ([locationName hasSuffix:@".ll"])) {
                        // CLANG bitcode. insert lli in front of argument list:
                        argc += 1;
                        argv = (char **)realloc(argv, sizeof(char*) * argc);
                        // Move everything one step up
                        for (int i = argc; i >= 1; i--) { argv[i] = argv[i-1]; }
                        argv[1] = realloc(argv[1], locationName.length + 1);
                        strcpy(argv[1], locationName.UTF8String);
                        argv[0] = strdup("lli"); // this argument is new
                        break;
                    } else if ([locationName hasSuffix:@".wasm"]) {
                        // insert wasm in front of argument list:
                        argc += 1;
                        argv = (char **)realloc(argv, sizeof(char*) * (argc + 1));
                        // Move everything one step up
                        for (int i = argc-1; i >= 1; i--) { argv[i] = argv[i-1]; }
                        argv[1] = realloc(argv[1], locationName.length + 1);
                        strcpy(argv[1], locationName.UTF8String);
                        argv[0] = strdup("wasm"); // this argument is new
                        break;
                    } else {
                        if (isRealCommand(locationName.UTF8String)) {
                            cmdIsReal = true;
                            NSData *data = [NSData dataWithContentsOfFile:locationName]; // You have the data. Conversion to String probably failed.
                            NSString *fileContent = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                            if ((fileContent == nil) && (data.length > 0)) {
                                // Conversion to string failed with UTF8. Try with Ascii as a backup:
                                fileContent =  [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
                            }
                            NSString* firstLine;
                            if (fileContent != nil) {
                                NSRange firstLineRange = [fileContent rangeOfString:@"\n"];
                                if (firstLineRange.length > 0) {
                                    firstLineRange.length = firstLineRange.location;
                                } else {
                                    firstLineRange.length = fileContent.length;
                                }
                                firstLineRange.location = 0;
                                firstLine = [fileContent substringWithRange:firstLineRange];
                            }
                            if ([firstLine hasPrefix:@"#!"]) {
                                // 1) get script language name
                                // The last word of the line is the command. This covers all of the cases encountered:
                                // "#! /usr/bin/python", "#! /usr/local/bin/python" and "#! /usr/bin/myStrangePath/python" are all OK.
                                // We also accept "#! /usr/bin/env python" because it is used.
                                // Special case: scripts that begin with "#! /bin/sh" will be executed with dash
                                // And we want to accept "#! bc -l" too, so we can have multiple arguments.
                                // Take alphanumericCharacterSet and invert it.
                                firstLine = [firstLine substringFromIndex:2]; // remove "#!" at the beginning
                                firstLine = [firstLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]; // remove any extra space
                                
                                NSArray<NSString*> *firstLineComponents = [firstLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                NSMutableArray<NSString*> *components = [firstLineComponents mutableCopy];
                                if ([components.firstObject hasSuffix:@"env"]) {
                                    // /usr/bin/env <command>
                                    [components removeObjectAtIndex:0];
                                }
                                // Extract stript name by removing the path:
                                NSString* scriptNameString = components[0];
                                NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString:@"/"];
                                NSArray<NSString*> *scriptComponents = [scriptNameString componentsSeparatedByCharactersInSet:separators];
                                scriptNameString = scriptComponents.lastObject;
                                if ([scriptNameString isEqualToString:@"sh"])
                                    scriptNameString = @"dash";
                                if ([scriptNameString isEqualToString:@"node"])
                                    scriptNameString = @"jsc";
                                // If scriptNameString is a file that exists in PATH and has webAssembly signature, then insert "wasm script". Other cases?
                                components[0] = scriptNameString;
                                NSString* beforeCommand = beforeScriptCommandName(scriptNameString);
                                if (beforeCommand != NULL) {
                                    [components removeObjectAtIndex:0];
                                    NSArray<NSString*> *newComponents = [beforeCommand componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                                    [components insertObjects:newComponents atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newComponents.count)]];
                                }
                                unsigned long numComponents = components.count;
                                if (numComponents > 0) {
                                    // 2) insert all arguments at beginning of argument list:
                                    argc += numComponents;
                                    argv = (char **)realloc(argv, sizeof(char*) * (argc + 1));
                                    // Move everything numComponents step up
                                    for (int i = argc; i >= numComponents; i--) { argv[i] = argv[i-numComponents]; }
                                    // Change the location of the file (from "command" to "/actual/full/path/command"):
                                    // This pointer existed before
                                    argv[numComponents] = realloc(argv[numComponents], locationName.length + 1);
                                    strcpy(argv[numComponents], locationName.UTF8String);
                                    // Copy all arguments without change (except the first):
                                    for (int i = 0; i < numComponents; i++) {
                                        argv[i] = strdup(components[i].UTF8String); // creates new pointers
                                    }
                                    break;
                                }
                            } else {
                                // Detect WebAssembly file signature: '\0asm' (begins with 0, so not a string)
                                if ((data.length >0) && (((char*)data.bytes)[0] == 0)) {
                                    // fileContent = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
                                    NSRange signatureRange = NSMakeRange(1, 3);
                                    firstLine = [fileContent substringWithRange:signatureRange];
                                }
                                if ([firstLine isEqualToString:@"asm"]) {
                                    // WebAssembly file, identified by signature:
                                    // Same code as above, but single command:
                                    argc += 1;
                                    argv = (char **)realloc(argv, sizeof(char*) * (argc + 1));
                                    // Move everything numComponents step up
                                    for (int i = argc; i >= 1; i--) { argv[i] = argv[i-1]; }
                                    // Change the location of the file (from "command" to "/actual/full/path/command"):
                                    // This pointer existed before
                                    argv[1] = realloc(argv[1], locationName.length + 1);
                                    strcpy(argv[1], locationName.UTF8String);
                                    // Copy all arguments without change (except the first):
                                    argv[0] = strdup("wasm"); // creates new pointer
                                    break;
                                }
                            }
                        } else {
                            cmdIsReal = false;
                        }
                    }
                    if (cmdIsAFile) break; // else keep going through the path elements.
                }
            }
            if (!cmdIsReal || (cmdIsAPath && !cmdIsAFile)) {
                // argv[0] is a file that doesn't exist, or has size 0. Probably one of our commands.
                // Replace with its name:
                char* newName = basename(argv[0]);
                argv[0] = realloc(argv[0], strlen(newName) + 1);
                strcpy(argv[0], newName);
            }
        }
        NSLog(@"After command parsing, stdout %d stderr %d \n", fileno(params->stdout),  fileno(params->stderr));
        // fprintf(thread_stderr, "Command after parsing: ");
        // for (int i = 0; i < argc; i++)
        //    fprintf(thread_stderr, "[%s] ", argv[i]);
        // We've reached this point: either the command is a file, from a script we support,
        // and we have inserted the name of the script at the beginning, or it is a builtin command
        int (*function)(int ac, char** av) = NULL;
        if (commandList == nil) initializeCommandList();
        NSString* commandName = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
        if ([commandName isEqualToString:@"sh"]) {
            // if it's sh -c commands (or sh -c command1 || command2), we continue using our own sh_main
            // (for continuity: keep our known bugs, rather than break things).
            // otherwise we use dash_main:
            bool cflag = false;
            // Technically, "-c" should be the first argument of sh, so no need to scan through all arguments
            // But we're being extra careful.
            for (int i = 1; i < argc; i++) {
                if (argv[i][0] == '-') {
                    if (strlen(argv[i]) == 1) continue;
                    if (strchr(argv[i], 'c') != NULL) {
                        cflag = true;
                        break;
                    }
                } else break;
            }
            if (!cflag) { // We need to know it's dash, not sh.
                commandName = @"dash";
                argv[0] = realloc(argv[0], 5);
                strcpy(argv[0], "dash");
            }
        }
        //
        NSArray* commandStructure = [commandList objectForKey: commandName];
        void* handle = NULL;
        if (commandStructure != nil) {
            NSString* libraryName = commandStructure[0];
            NSString* functionName = commandStructure[1];
            // Python, Perl and TeX can have multiple commands calling themselves:
            // hasPrefix covers python, python3, python3.9.
            if ([commandName hasPrefix: @"python"]) {
                // Ability to start multiple python3 scripts (required for Jupyter notebooks):
                // start by increasing the number of the interpreter, until we're out.
                int numInterpreter = 0;
                if ((currentPythonInterpreter < numPythonInterpreters) && (!PythonIsRunning[currentPythonInterpreter])) {
                    numInterpreter = currentPythonInterpreter;
                    currentPythonInterpreter++;
                } else {
                    NSDate *start = [NSDate date];
                    NSDate *now = [NSDate date];
                    NSTimeInterval timeInterval = [now timeIntervalSinceDate:start];
                    while (timeInterval < 1) { // keep trying for 1 second
                        while  (numInterpreter < numPythonInterpreters) {
                            if (PythonIsRunning[numInterpreter] == false) break;
                            numInterpreter++;
                        }
                        if (numInterpreter < numPythonInterpreters) break;
                        numInterpreter = 0;
                        now = [NSDate date];
                        timeInterval = [now timeIntervalSinceDate:start];
                    }
                    if (numInterpreter >= numPythonInterpreters) {
                        if (showPythonInterpreterAlert) {
                            // Only show this alert once per session:
                            display_alert(@"Too many Python scripts", @"There are too many Python interpreters running at the same time. Try closing some of them.");
                            NSLog(@"%@", @"Too many python scripts running simultaneously. Try closing some notebooks.\n");
                            showPythonInterpreterAlert = false;
                            currentSession->global_errno = ENOENT;
                        }
                        function = &too_many_scripts;
                        functionName = @"notAValidCommand";
                        argv[0][0] = 'x'; // prevent reinitialization in cleanup_function
                    } else {
                        currentPythonInterpreter = numInterpreter;
                    }
                }
                if ((numInterpreter == 0) && (strlen(argv[0]) > 7)) {
                    // python3.x creates issues, so we truncate to 'python3'
                    argv[0][7] = 0;
                }
                if ((numInterpreter >= 0) && (numInterpreter < numPythonInterpreters)) {
                    params->numInterpreter = numInterpreter;
                    PythonIsRunning[numInterpreter] = true;
                    if (numInterpreter > 0) {
                        if ([commandName isEqualToString: @"python"]) {
                            // Add space for an extra letter at the end of "python" (+1 for "A", +1 for '\0')
                            argv[0] = realloc(argv[0], strlen(argv[0]) + 2);
                        }
                        char suffix[2];
                        suffix[0] = 'A' + (numInterpreter - 1);
                        suffix[1] = 0;
                        argv[0][6] = suffix[0];
                        argv[0][7] = 0;
                        commandName = [@"python" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                        NSLog(@"Python new commandName: %s", commandName.UTF8String);
                        libraryName = [[commandName stringByAppendingString: @".framework/"] stringByAppendingString: commandName];
                        NSLog(@"Python new libraryName: %s", libraryName.UTF8String);
                    }
                }
            } else if ([commandName hasPrefix: @"perl"]) {
                // Ability to start multiple perl scripts (required for cpan):
                // start by increasing the number of the interpreter, until we're out.
                int numInterpreter = 0;
                if (currentPerlInterpreter < numPerlInterpreters) {
                    numInterpreter = currentPerlInterpreter;
                    currentPerlInterpreter++;
                } else {
                    while  (numInterpreter < numPerlInterpreters) {
                        if (PerlIsRunning[numInterpreter] == false) break;
                        numInterpreter++;
                    }
                    if (numInterpreter >= numPerlInterpreters) {
                        display_alert(@"Too many Perl scripts", @"There are too many Perl interpreters running at the same time. Try closing some of them.");
                        NSLog(@"%@", @"Too many perl scripts running simultaneously.\n");
                        function = &too_many_scripts;
                        functionName = @"notAValidCommand";
                        currentSession->global_errno = ENOENT;
                        argv[0][0] = 'x'; // prevent reinitialization in cleanup_function
                    }
                }
                if ((numInterpreter >= 0) && (numInterpreter < numPerlInterpreters)) {
                    params->numInterpreter = numInterpreter;
                    PerlIsRunning[numInterpreter] = true;
                    NSLog(@"Starting a Perl interpreter: %d", params->numInterpreter);
                    if (numInterpreter > 0) {
                        char suffix[2];
                        suffix[0] = 'A' + (numInterpreter - 1);
                        suffix[1] = 0;
                        commandName = [@"perl" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                        libraryName = [libraryName stringByReplacingOccurrencesOfString:@"perl" withString:commandName];
                    }
                }
            } else if ([TeXcommands containsObject: commandName]) {
                // It's a TeX command. Ability to start multiple TeX commands (required for Tikz)
                // start by increasing the number of the interpreter, until we're out.
                int numInterpreter = 0;
                if (currentTeXInterpreter < numTeXInterpreters) {
                    numInterpreter = currentTeXInterpreter;
                    currentTeXInterpreter++;
                } else {
                    while  (numInterpreter < numTeXInterpreters) {
                        if (TeXIsRunning[numInterpreter] == false) break;
                        numInterpreter++;
                    }
                    if (numInterpreter >= numTeXInterpreters) {
                        display_alert(@"Too many TeX scripts", @"There are too many TeX interpreters running at the same time. Try closing some of them.");
                        NSLog(@"%@", @"Too many TeX scripts running simultaneously.\n");
                        function = &too_many_scripts;
                        functionName = @"notAValidCommand";
                        currentSession->global_errno = ENOENT;
                        argv[0][0] = 'x'; // prevent reinitialization in cleanup_function
                    }
                }
                if ((numInterpreter >= 0) && (numInterpreter < numTeXInterpreters)) {
                    params->numInterpreter = numInterpreter;
                    TeXIsRunning[numInterpreter] = true;
                    if (numInterpreter > 0) {
                        // There are multiple TeX commands, and they can start each other.
                        char suffix[2];
                        suffix[0] = 'A' + (numInterpreter - 1);
                        suffix[1] = 0;
                        // libraryName can be pdftex, luatex or luahbtex:
                        if ([libraryName hasPrefix: @"pdftex"]) {
                            NSString* newName = [@"pdftex" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                            libraryName = [libraryName stringByReplacingOccurrencesOfString:@"pdftex" withString:newName];
                        } else if ([libraryName hasPrefix: @"luatex"]) {
                            NSString* newName = [@"luatex" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                            libraryName = [libraryName stringByReplacingOccurrencesOfString:@"luatex" withString:newName];
                        } else if ([libraryName hasPrefix: @"luahbtex"]) {
                            NSString* newName = [@"luahbtex" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                            libraryName = [libraryName stringByReplacingOccurrencesOfString:@"luahbtex" withString:newName];
                        } else if ([libraryName hasPrefix: @"xetex"]) {
                            NSString* newName = [@"xetex" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                            libraryName = [libraryName stringByReplacingOccurrencesOfString:@"xetex" withString:newName];
                        } else if ([libraryName hasPrefix: @"xdvipdfmx"]) {
                            NSString* newName = [@"xdvipdfmx" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                            libraryName = [libraryName stringByReplacingOccurrencesOfString:@"xdvipdfmx" withString:newName];
                        }
                    }
                }
            } else if ([commandName hasPrefix: @"dash"]) {
                // Ability to start multiple dash commands:
                // start by increasing the number of the interpreter, until we're out.
                int numInterpreter = 0;
                if (currentDashCommand < numDashCommands) {
                    numInterpreter = currentDashCommand;
                    currentDashCommand++;
                } else {
                    NSDate *start = [NSDate date];
                    NSDate *now = [NSDate date];
                    NSTimeInterval timeInterval = [now timeIntervalSinceDate:start];
                    while (timeInterval < 1) { // keep trying for 1 second
                        while  (numInterpreter < numDashCommands) {
                            if (dashIsRunning[numInterpreter] == false) break;
                            numInterpreter++;
                        }
                        if (numInterpreter < numDashCommands) break;
                        numInterpreter = 0;
                        now = [NSDate date];
                        timeInterval = [now timeIntervalSinceDate:start];
                    }
                    if (numInterpreter >= numDashCommands) {
                        display_alert(@"Too many dash scripts", @"There are too many dash scripts running at the same time. Try closing some of them.");
                        NSLog(@"%@", @"Too many dash scripts running simultaneously.\n");
                        functionName = @"notAValidCommand";
                        currentSession->global_errno = ENOENT;
                        argv[0][0] = 'x'; // prevent reinitialization in cleanup_function
                    }
                }
                if ((numInterpreter >= 0) && (numInterpreter < numDashCommands)) {
                    params->numInterpreter = numInterpreter;
                    dashIsRunning[numInterpreter] = true;
                    NSLog(@"Starting a dash shell: %d", params->numInterpreter);
                    if (numInterpreter > 0) {
                        char suffix[2];
                        suffix[0] = 'A' + (numInterpreter - 1);
                        suffix[1] = 0;
                        commandName = [@"dash" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                        libraryName = [libraryName stringByReplacingOccurrencesOfString:@"dash" withString:commandName];
                    }
                }
            } else if ([commandName isEqualToString: @"ssh"] || [commandName isEqualToString: @"scp"] || [commandName isEqualToString: @"sftp"]) {
                // Ability to start multiple ssh commands:
                // start by increasing the number of the interpreter, until we're out.
                int numInterpreter = 0;
                if (currentSshCommand < numSshCommands) {
                    numInterpreter = currentSshCommand;
                    currentSshCommand++;
                } else {
                    NSDate *start = [NSDate date];
                    NSDate *now = [NSDate date];
                    NSTimeInterval timeInterval = [now timeIntervalSinceDate:start];
                    while (timeInterval < 1) { // keep trying for 1 second
                        while  (numInterpreter < numSshCommands) {
                            if (sshIsRunning[numInterpreter] == false) break;
                            numInterpreter++;
                        }
                        if (numInterpreter < numSshCommands) break;
                        numInterpreter = 0;
                        now = [NSDate date];
                        timeInterval = [now timeIntervalSinceDate:start];
                    }
                    if (numInterpreter >= numSshCommands) {
                        display_alert(@"Too many ssh commands", @"There are too many ssh commands running at the same time. Try closing some of them.");
                        NSLog(@"%@", @"Too many ssh scripts running simultaneously.\n");
                        functionName = @"notAValidCommand";
                        currentSession->global_errno = ENOENT;
                        argv[0][0] = 'x'; // prevent reinitialization in cleanup_function
                    }
                }
                if ((numInterpreter >= 0) && (numInterpreter < numSshCommands)) {
                    params->numInterpreter = numInterpreter;
                    sshIsRunning[numInterpreter] = true;
                    NSLog(@"Starting a ssh command: %d", params->numInterpreter);
                    if (numInterpreter > 0) {
                        char suffix[2];
                        suffix[0] = 'A' + (numInterpreter - 1);
                        suffix[1] = 0;
                        commandName = [@"ssh_cmd" stringByAppendingString: [NSString stringWithCString: suffix encoding:NSUTF8StringEncoding]];
                        libraryName = [libraryName stringByReplacingOccurrencesOfString:@"ssh_cmd" withString:commandName];
                    }
                }
            }
            if ([libraryName isEqualToString: @"SELF"]) handle = RTLD_SELF;  // commands defined in ios_system.framework
            else if ([libraryName isEqualToString: @"MAIN"]) handle = RTLD_MAIN_ONLY; // commands defined in main program
            else handle = dlopen(libraryName.UTF8String, RTLD_LAZY | RTLD_GLOBAL); // commands defined in dynamic library
            if (handle == NULL) {
                char* errorLoading = strdup(dlerror());
                fprintf(thread_stderr, "Failed loading %s from %s, cause = %s\n", commandName.UTF8String, libraryName.UTF8String, errorLoading);
                NSLog(@"Failed loading %s from %s, cause = %s\n", commandName.UTF8String, libraryName.UTF8String, errorLoading);
                NSString* fileLocation = [[NSBundle mainBundle] pathForResource:libraryName ofType:nil];
                free(errorLoading);
            } else {
                function = dlsym(handle, functionName.UTF8String);
                NSLog(@"Loading %s from %s", functionName.UTF8String, libraryName.UTF8String);
                if (function == NULL) {
                    char* errorLoading = strdup(dlerror());
                    fprintf(thread_stderr, "Failed loading %s from %s, cause = %s\n", functionName.UTF8String, libraryName.UTF8String, errorLoading);
                    NSLog(@"Failed loading %s from %s, cause = %s\n", commandName.UTF8String, libraryName.UTF8String, errorLoading);
                    free(errorLoading);
                }
            }
        }
        if (function == NULL) {
            function = &command_not_found;
            currentSession->global_errno = ENOENT;
            // function = dlsym(RTLD_SELF, "command_not_found");
        }
        if (function) {
            // We run the function in a thread because there are several
            // points where we can exit from a shell function.
            // Commands call pthread_exit instead of exit
            // thread is attached, could also be un-attached
            params->argc = argc;
            params->argv = argv;
            params->function = function;
            params->dlHandle = handle;
            params->isPipeIn = (params->stdin != thread_stdin);
            params->isPipeOut = (params->stdout != thread_stdout);
            if (params->stdout != NULL)
                NSLog(@"params->stdout: %d thread_stdout: %d \n", fileno(params->stdout), fileno(thread_stdout));
            if (params->stdin != NULL)
                NSLog(@"params->stdin: %d thread_stdin: %d \n", fileno(params->stdin), fileno(thread_stdin));
            params->isPipeErr = (params->stderr != thread_stderr) && (params->stderr != params->stdout);
            params->storeRootThread = false;
            // params->session = currentSession;
            // Before starting, do we have enough file descriptors available?
            int numFileDescriptorsOpen = 0;
            for (int fd = 0; fd < limitFilesOpen.rlim_cur; fd++) {
                errno = 0;
                int flags = fcntl(fd, F_GETFD, 0);
                if (flags == -1 && errno) {
                    continue;
                }
                ++numFileDescriptorsOpen ;
            }
            NSLog(@"\nNum file descriptors opened = %d limit= %llu\n", numFileDescriptorsOpen, limitFilesOpen.rlim_cur);
            // fprintf(stderr, "Num file descriptor = %d\n", numFileDescriptorsOpen);
            // We assume 128 file descriptors will be enough for a single command.
            if (numFileDescriptorsOpen + 128 > limitFilesOpen.rlim_cur) {
                limitFilesOpen.rlim_cur += 1024;
                int res = setrlimit(RLIMIT_NOFILE, &limitFilesOpen);
                // Check the result:
                getrlimit(RLIMIT_NOFILE, &limitFilesOpen);
                if (res == 0) NSLog(@"[Info] Increased file descriptor limit to = %llu OPEN_MAX= %d\n", limitFilesOpen.rlim_cur, OPEN_MAX);
                else NSLog(@"[Warning] Failed to increased file descriptor limit to = %llu\n", limitFilesOpen.rlim_cur);
            }
            NSLog(@"Starting command: %s, currentSession->isMainThread: %d", commandName.UTF8String, currentSession->isMainThread);
            if ([commandName isEqualToString:@"wasm"])
                startedPreparingWebAssemblyCommand();
            if (currentSession->isMainThread) {
                params->storeRootThread = true;
                // I'm still not sure why this is needed specially for dash and no other commands:
                // Needed for pipes
                if ([commandName isEqualToString: @"dash"]) {
                    params->storeRootThread = false;
                }
                bool commandOperatesOnFiles = ([commandStructure[3] isEqualToString:@"file"] ||
                                               [commandStructure[3] isEqualToString:@"directory"] ||
                                               params->isPipeOut || params->isPipeErr);
                NSString* currentPath = [fileManager currentDirectoryPath];
                commandOperatesOnFiles &= (currentPath != nil);
                if (commandOperatesOnFiles) {
                    // Send a signal to the system that we're going to change the current directory:
                    NSURL* currentURL = [NSURL fileURLWithPath:currentPath];
                    NSFileCoordinator *fileCoordinator =  [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                    [fileCoordinator coordinateWritingItemAtURL:currentURL options:0 error:NULL byAccessor:^(NSURL *currentURL) {
                        currentSession->isMainThread = false;
                        volatile pthread_t _tid = NULL;
                        pthread_create(&_tid, NULL, run_function, params);
                        while (_tid == NULL) { }
                        // ios_storeThreadId(_tid);
                        if (currentSession->mainThreadId == NULL) currentSession->mainThreadId = _tid;
                        // Wait for this process to finish:
						if (joinMainThread) {
							pthread_join(_tid, NULL);
							// If there are auxiliary process, also wait for them:
							if (currentSession->lastThreadId > 0) pthread_join(currentSession->lastThreadId, NULL);
							currentSession->lastThreadId = 0;
							currentSession->current_command_root_thread = 0;
						} else {
							pthread_detach(_tid); // a thread must be either joined or detached
						}
                        currentSession->isMainThread = true;
                    }];
                } else {
                    currentSession->isMainThread = false;
                    volatile pthread_t _tid = NULL;
                    pthread_create(&_tid, NULL, run_function, params);
                    while (_tid == NULL) { }
                    // ios_storeThreadId(_tid);
                    if (currentSession->mainThreadId == NULL) currentSession->mainThreadId = _tid;
                    // Wait for this process to finish:
					if (joinMainThread) {
						pthread_join(_tid, NULL);
						// If there are auxiliary process, also wait for them:
						if (currentSession->lastThreadId > 0) pthread_join(currentSession->lastThreadId, NULL);
						currentSession->lastThreadId = 0;
						currentSession->current_command_root_thread = 0;
					} else {
						pthread_detach(_tid); // a thread must be either joined or detached
					}
                    currentSession->isMainThread = true;
                }
            } else {
                NSLog(@"Starting command %s, global_errno= %d\n", command, currentSession->global_errno);
                // Don't send signal if not in main thread. Also, don't join threads.
                volatile pthread_t _tid_local = NULL;
                pthread_create(&_tid_local, NULL, run_function, params);
                // The last command on the command line (with multiple pipes) will be created first
                while (_tid_local == NULL) { }; // Wait until thread has actually started
                // fprintf(stderr, "Started thread = %x\n", _tid_local);
                if (currentSession->lastThreadId == 0) currentSession->lastThreadId = _tid_local; // will be joined later
                else pthread_detach(_tid_local); // a thread must be either joined or detached.
            }
        } else {
            fprintf(params->stderr, "%s: command not found\n", argv[0]);
            NSLog(@"%s: command not found\n", argv[0]);
            free(argv);
            // If command output was redirected to a pipe, we still need to close it.
            // (to warn the other command that it can stop waiting)
            // We still need this step because there can be multiple pipes.
            if (params->stdout != currentSession->stdout) {
                fclose(params->stdout);
            }
            if ((params->stderr != currentSession->stderr) && (params->stderr != params->stdout)) {
                fclose(params->stderr);
            }
            if ((handle != NULL) && (handle != RTLD_SELF)
                && (handle != RTLD_MAIN_ONLY)
                && (handle != RTLD_DEFAULT) && (handle != RTLD_NEXT))
                dlclose(handle);
            free(params); // This was malloc'ed in ios_system
            ios_storeThreadId(0);
            currentSession->global_errno = 127;
            // TODO: this should also raise an exception, for python scripts
        } // if (function)
    } else { // argc != 0
        ios_storeThreadId(0);
        free(argv); // argv is otherwise freed in cleanup_function
        free(dontExpand);
        free(params);
    }
    NSLog(@"returning from ios_system, global_errno= %d\n", currentSession->global_errno);
    free(originalCommand); // releases cmd, which was a strdup of inputCommand
    fflush(thread_stdin);
    fflush(thread_stdout);
    fflush(thread_stderr);
    return currentSession->global_errno;
}

NSArray<NSString *> * pathNormalizeArray(NSArray<NSString *> * parts, BOOL allowAboveRoot) {
  NSMutableArray<NSString *> * res = [[NSMutableArray alloc] init];
  for (NSString * p in parts) {
    // ignore empty parts
    if (p.length == 0 || [p isEqualToString:@"."] || [p isEqualToString:@"/"]) {
      continue;
    }
    
    if ([p isEqualToString: @".."]) {
      if (res.count && ![@".." isEqualToString: [res lastObject]]) {
        [res removeLastObject];
      } else if (allowAboveRoot) {
        [res addObject: p];
      }
     } else {
      [res addObject: p];
    }
  }
  
  return res;
}

NSString * pathNormalize(NSString *path) {
  BOOL isAbsolute = [path hasPrefix:@"/"];
  BOOL trailingSlash = [path hasSuffix:@"/"];
  
  NSString * result = [pathNormalizeArray([path pathComponents], !isAbsolute) componentsJoinedByString: @"/"];
  
  if (!result.length && !isAbsolute) {
    result = @".";
  }
  
  if (result.length && trailingSlash) {
    result = [result stringByAppendingString:@"/"];
  }
  
  return [(isAbsolute ? @"/" : @"") stringByAppendingString:result];
}


NSString * pathJoin(NSString * segmentA, NSString * segmentB) {
  NSMutableString *path = [[NSMutableString alloc] init];
  NSString * a = segmentA ?: @"";
  NSString * b = segmentB ?: @"";
  
  if ([b hasPrefix:@"/"]) {
    return pathNormalize(b);
  }
  
  if (a.length) {
    [path appendString: a];
    if (b.length) {
      [path appendString:@"/"];
      [path appendString:b];
    }
  } else if (b.length) {
    [path appendString: b];
  }
  
  return pathNormalize(path);
}

//
char* ios_getPythonLibraryName(void) {
    // Ability to start multiple python3 scripts, expanded for commands that start python3 as a dynamic library.
    // (mostly vim, right now)
    // start by increasing the number of the interpreter, until we're out.
    int numInterpreter = 0;
    if ((currentPythonInterpreter < numPythonInterpreters) && (!PythonIsRunning[currentPythonInterpreter])) {
        numInterpreter = currentPythonInterpreter;
        currentPythonInterpreter++;
    } else {
        while  (numInterpreter < numPythonInterpreters) {
            if (PythonIsRunning[numInterpreter] == false) break;
            numInterpreter++;
        }
        if (numInterpreter >= numPythonInterpreters) {
            // NSLog(@"ios_getPythonLibraryName: returning NULL\n");
            return NULL;
        } else {
            currentPythonInterpreter = numInterpreter;
        }
    }
    char* libraryName = NULL;
    if ((numInterpreter >= 0) && (numInterpreter < numPythonInterpreters)) {
        PythonIsRunning[numInterpreter] = true;
        if (numInterpreter > 0) {
            libraryName = strdup("pythonA");
            libraryName[6] = 'A' + (numInterpreter - 1);
        } else {
            libraryName = strdup("python3_ios");
        }
        NSLog(@"ios_getPythonLibraryName: returning %s\n", libraryName);
        return libraryName;
    }
    NSLog(@"ios_getPythonLibraryName: returning NULL\n");
    return NULL;
}

void ios_releasePythonLibraryName(char* name) {
    NSLog(@"ios_releasePythonLibraryName: releasing %s\n", name);
    char libNumber = name[6];
    if (libNumber == '3') PythonIsRunning[0] = false;
    else {
        libNumber -= 'A' - 1;
        if ((libNumber > 0) && (libNumber < MaxPythonInterpreters))
            PythonIsRunning[libNumber] = false;
    }
    free(name);
}
