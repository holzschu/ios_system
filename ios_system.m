//
//  ios_system.m
//
//  Created by Nicolas Holzschuch on 17/11/2017.
//  Copyright © 2017 N. Holzschuch. All rights reserved.
//

#import <Foundation/Foundation.h>
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
// is executable, looking at "x" bit. Other methods fails on iOS:
#define S_ISXXX(m) ((m) & (S_IXUSR | S_IXGRP | S_IXOTH))
// Sideloading: when you compile yourself, as opposed to uploading on the app store
// If true, all functions are enabled + debug messages if dylib not found.
// If false, you get a smaller set, but more compliance with AppStore rules.
// *Must* be false in the main branch releases.
bool sideLoading = false;

extern __thread int    __db_getopt_reset;
__thread FILE* thread_stdin;
__thread FILE* thread_stdout;
__thread FILE* thread_stderr;
__thread void* thread_context;

#import "sessionParameters.h"

NSMutableDictionary* sessionList;
sessionParameters* currentSession;

// replace system-provided exit() by our own:
void ios_exit(int n) {
    if (currentSession != NULL) currentSession.global_errno = n;
    pthread_exit(NULL);
}

int ios_getCommandStatus() {
    if (currentSession != NULL) return currentSession.global_errno;
    else return 0;
}

extern const char* ios_progname(void) {
    if (currentSession != NULL) return [currentSession.commandName UTF8String];
    else return getprogname();
}


typedef struct _functionParameters {
    int argc;
    char** argv;
    char** argv_ref;
    int (*function)(int ac, char** av);
    FILE *stdin, *stdout, *stderr;
    void* context;
    void* dlHandle;
    bool isPipeOut;
    bool isPipeErr;
} functionParameters;

static void cleanup_function(void* parameters) {
    // This function is called when pthread_exit() or ios_kill() is called
    functionParameters *p = (functionParameters *) parameters;
    fflush(thread_stdout);
    fflush(thread_stderr);
    // release parameters:
    for (int i = 0; i < p->argc; i++) free(p->argv_ref[i]);
    free(p->argv_ref);
    free(p->argv);
    if (p->isPipeOut) {
        // Close stdout if it won't be closed by another thread
        // (i.e. if it's different from the parent thread stdout)
        fclose(thread_stdout);
        thread_stdout = NULL;
    }
    if (p->isPipeErr) {
        fclose(thread_stderr);
        thread_stderr = NULL;
    }
    if ((p->dlHandle != RTLD_SELF) && (p->dlHandle != RTLD_MAIN_ONLY)
        && (p->dlHandle != RTLD_DEFAULT) && (p->dlHandle != RTLD_NEXT))
        dlclose(p->dlHandle);
    free(parameters); // This was malloc'ed in ios_system
}

static void* run_function(void* parameters) {
    // re-initialize for getopt:
    // TODO: move to __thread variable for optind too
    optind = 1;
    opterr = 1;
    optreset = 1;
    __db_getopt_reset = 1;
    functionParameters *p = (functionParameters *) parameters;
    thread_stdin  = p->stdin;
    thread_stdout = p->stdout;
    thread_stderr = p->stderr;
    thread_context = p->context;
    // Because some commands change argv, keep a local copy for release.
    p->argv_ref = (char **)malloc(sizeof(char*) * (p->argc + 1));
    for (int i = 0; i < p->argc; i++) p->argv_ref[i] = p->argv[i];
    pthread_cleanup_push(cleanup_function, parameters);
    p->function(p->argc, p->argv);
    pthread_cleanup_pop(1);
    return NULL;
}

static NSString* miniRoot = nil; // limit operations to below a certain directory (~, usually).
static NSDictionary *commandList = nil;
// do recompute directoriesInPath only if $PATH has changed
static NSString* fullCommandPath = @"";
static NSArray *directoriesInPath;

void initializeEnvironment() {
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
    setenv("SSL_CERT_FILE", [docsPath stringByAppendingPathComponent:@"cacert.pem"].UTF8String, 0); // SLL cacert.pem in ~/Documents/cacert.pem or [Cloud Drive]/cacert.pem
    // iOS already defines "HOME" as the home dir of the application
    if (sideLoading) {
        NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
        if (![fullCommandPath containsString:@"Library/bin"]) {
            NSString *binPath = [libPath stringByAppendingPathComponent:@"bin"];
            fullCommandPath = [[binPath stringByAppendingString:@":"] stringByAppendingString:fullCommandPath];
        }
        // if we use Python, we define a few more environment variables:
        setenv("PYTHONHOME", libPath.UTF8String, 0);  // Python scripts in ~/Library/lib/python3.6/
        setenv("PYZMQ_BACKEND", "cffi", 0);
        setenv("JUPYTER_CONFIG_DIR", [docsPath stringByAppendingPathComponent:@".jupyter"].UTF8String, 0);
        // hg config file in ~/Documents/.hgrc
        setenv("HGRCPATH", [docsPath stringByAppendingPathComponent:@".hgrc"].UTF8String, 0);
    }
    directoriesInPath = [fullCommandPath componentsSeparatedByString:@":"];
    setenv("PATH", fullCommandPath.UTF8String, 1); // 1 = override existing value
}

static char* parseArgument(char* argument, char* command) {
    // expand all environment variables, convert "~" to $HOME (only if localFile)
    // we also pass the shell command for some specific behaviour (don't do this for that command)
    NSString* argumentString = [NSString stringWithCString:argument encoding:NSUTF8StringEncoding];
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
        const char* variable = getenv([variable_string UTF8String]);
        if (variable) {
            // Okay, so this one exists.
            NSString* replacement_string = [NSString stringWithCString:variable encoding:NSUTF8StringEncoding];
            variable_string = [[NSString stringWithCString:"$" encoding:NSUTF8StringEncoding] stringByAppendingString:variable_string];
            argumentString = [argumentString stringByReplacingOccurrencesOfString:variable_string withString:replacement_string];
        } else cannotExpand = true; // found a variable we can't expand. stop trying for this argument
    }
    // 2) Tilde conversion: replace "~" with $HOME
    // If there are multiple users on iOS, this code will need to be changed.
    if([argumentString hasPrefix:@"~"]) {
        // So it begins with "~". We can't use stringByExpandingTildeInPath because apps redefine HOME
        NSString* replacement_string;
        if (miniRoot == nil)
            replacement_string = [NSString stringWithCString:(getenv("HOME")) encoding:NSUTF8StringEncoding];
        else replacement_string = miniRoot;
        if (([argumentString hasPrefix:@"~/"]) || ([argumentString hasPrefix:@"~:"]) || ([argumentString length] == 1)) {
            NSString* test_string = @"~";
            argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange(0, 1)];
        }
    }
    // Also convert ":~something" in PATH style variables
    // We don't use these yet, but we could.
    // We do this expansion only for setenv
    if (strcmp(command, "setenv") == 0) {
        // This is something we need to avoid if the command is "scp" or "sftp"
        if ([argumentString containsString:@":~"]) {
            NSString* homeDir;
            if (miniRoot == nil) homeDir = [NSString stringWithCString:(getenv("HOME")) encoding:NSUTF8StringEncoding];
            else homeDir = miniRoot;
            // Only 1 possibility: ":~" (same as $HOME)
            if (homeDir.length > 0) {
                if ([argumentString containsString:@":~/"]) {
                    NSString* test_string = @":~/";
                    NSString* replacement_string = [[NSString stringWithCString:":" encoding:NSUTF8StringEncoding] stringByAppendingString:homeDir];
                    replacement_string = [replacement_string stringByAppendingString:[NSString stringWithCString:"/" encoding:NSUTF8StringEncoding]];
                    argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string];
                } else if ([argumentString hasSuffix:@":~"]) {
                    NSString* test_string = @":~";
                    NSString* replacement_string = [[NSString stringWithCString:":" encoding:NSUTF8StringEncoding] stringByAppendingString:homeDir];
                    argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange([argumentString length] - 2, 2)];
                } else if ([argumentString hasSuffix:@":"]) {
                    NSString* test_string = @":";
                    NSString* replacement_string = [[NSString stringWithCString:":" encoding:NSUTF8StringEncoding] stringByAppendingString:homeDir];
                    argumentString = [argumentString stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange([argumentString length] - 2, 2)];
                }
            }
        }
    }
    const char* newArgument = [argumentString UTF8String];
    if (strcmp(argument, newArgument) == 0) return argument; // nothing changed
    // Make sure the argument is reallocated, so it can be free-ed
    char* returnValue = realloc(argument, strlen(newArgument));
    strcpy(returnValue, newArgument);
    return returnValue;
}


static void initializeCommandList()
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
        commandList = [mutableDict mutableCopy];
    }
}

int ios_setMiniRoot(NSString* mRoot) {
    BOOL isDir;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    if ([fileManager fileExistsAtPath:mRoot isDirectory:&isDir]) {
        if (isDir) {
            // fileManager has different ways of expressing the same directory.
            // We need to actually change to the directory to get its "real name".
            NSString* currentDir = [fileManager currentDirectoryPath];
            if ([fileManager changeCurrentDirectoryPath:mRoot]) {
                // also don't set the miniRoot if we can't go in there
                // get the real name for miniRoot:
                miniRoot = [fileManager currentDirectoryPath];
                // Back to where we we before:
                [fileManager changeCurrentDirectoryPath:currentDir];
                if (currentSession != nil) {
                    currentSession.currentDir = miniRoot;
                    currentSession.previousDirectory = miniRoot;
                }
                return 1; // mission accomplished
            }
        }
    }
    return 0;
}

// Called when 
int ios_setMiniRootURL(NSURL* mRoot) {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (currentSession == NULL) currentSession = [[sessionParameters alloc] init];
    currentSession.localMiniRoot = mRoot;
    currentSession.previousDirectory = currentSession.currentDir;
    currentSession.currentDir = [mRoot path];
    [fileManager changeCurrentDirectoryPath:[mRoot path]];
    return 1; // mission accomplished
}

int cd_main(int argc, char** argv) {
    if (currentSession == NULL) return 1;
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    if (argc > 1) {
        NSString* newDir = @(argv[1]);
        if (strcmp(argv[1], "-") == 0) {
            // "cd -" option to pop back to previous directory
            newDir = currentSession.previousDirectory;
        }
        BOOL isDir;
        // Check for permission and existence:
        if ([fileManager fileExistsAtPath:newDir isDirectory:&isDir]) {
            if (isDir) {
                if ([fileManager isReadableFileAtPath:newDir] &&
                    [fileManager changeCurrentDirectoryPath:newDir]) {
                    // We managed to change the directory.
                    // Was that allowed?
                    // Allowed "cd" = below miniRoot *or* below localMiniRoot
                    NSString* resultDir = [fileManager currentDirectoryPath];
                    bool notAllowedCd = ((miniRoot != nil) && (![resultDir hasPrefix:miniRoot]));
                    if (notAllowedCd && currentSession.localMiniRoot)
                        notAllowedCd = !([resultDir hasPrefix:[currentSession.localMiniRoot path]]);
                    if (notAllowedCd) {
                        fprintf(thread_stderr, "cd: %s: permission denied\n", [newDir UTF8String]);
                        // If the user tried to go above the miniRoot, set it to miniRoot
                        if ([miniRoot hasPrefix:resultDir]) {
                            [fileManager changeCurrentDirectoryPath:miniRoot];
                            currentSession.currentDir = miniRoot;
                            currentSession.previousDirectory = currentSession.currentDir;
                        } else {
                            // go back to where we were before:
                            [fileManager changeCurrentDirectoryPath:currentSession.currentDir];
                        }
                    } else {
                        currentSession.previousDirectory = currentSession.currentDir;
                    }
                } else fprintf(thread_stderr, "cd: %s: permission denied\n", [newDir UTF8String]);
            }
            else  fprintf(thread_stderr, "cd: %s: not a directory\n", [newDir UTF8String]);
        } else {
            fprintf(thread_stderr, "cd: %s: no such file or directory\n", [newDir UTF8String]);
        }
    } else { // [cd] Help, I'm lost, bring me back home
        currentSession.previousDirectory = [fileManager currentDirectoryPath];

        if (miniRoot != nil) {
            [fileManager changeCurrentDirectoryPath:miniRoot];
        } else {
            [fileManager changeCurrentDirectoryPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
        }
    }
    currentSession.currentDir = [fileManager currentDirectoryPath];
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
    NSArray* valuesFromDict = [commandList objectForKey: [NSString stringWithCString:inputCmd encoding:NSUTF8StringEncoding]];
    // we could dlopen() here, but that would defeat the purpose
    if (valuesFromDict == nil) return 0;
    else return 1;
}

// Where to direct input/output of the next thread:
static __thread FILE* child_stdin = NULL;
static __thread FILE* child_stdout = NULL;
static __thread FILE* child_stderr = NULL;

FILE* ios_popen(const char* inputCmd, const char* type) {
    // Save existing streams:
    int fd[2] = {0};
    const char* command = inputCmd;
    // skip past all spaces
    while ((command[0] == ' ') && strlen(command) > 0) command++;
    // TODO: skip past "/bin/sh -c" and "sh -c"
    if (pipe(fd) < 0) { return NULL; } // Nothing we can do if pipe fails
    // NOTES: fd[0] is set up for reading, fd[1] is set up for writing
    // fpout = fdopen(fd[1], "w");
    // fpin = fdopen(fd[0], "r");
    if (type[0] == 'w') {
        // open pipe for reading
        child_stdin = fdopen(fd[0], "r");
        // launch command:
        ios_system(command);
        return fdopen(fd[1], "w");
    } else if (type[0] == 'r') {
        // open pipe for writing
        // set up streams for thread
        child_stdout = fdopen(fd[1], "w");
        // launch command:
        ios_system(command);
        return fdopen(fd[0], "r");
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
    char* cmd = malloc((cmdLength  + 2 * argc) * sizeof(char)); // space for quotes
    strcpy(cmd, argv[0]);
    argc = 1;
    while (argv[argc] != NULL) {
        if (strstr(argv[argc], " ")) {
            // argument contains spaces. Enclose it into quotes:
            if (strstr(argv[argc], "\"") == NULL) {
                // argument does not contain ". Enclose with "
                strcat(cmd, " \"");
                strcat(cmd, argv[argc]);
                strcat(cmd, "\"");
                argc++;
                continue;
            }
            if (strstr(argv[argc], "'") == NULL) {
                // Enclose with '
                strcat(cmd, " '");
                strcat(cmd, argv[argc]);
                strcat(cmd, "'");
                argc++;
                continue;
            }
            fprintf(thread_stderr, "Don't know what to do with this argument, sorry: %s\n", argv[argc]);
        }
        strcat(cmd, " ");
        strcat(cmd, argv[argc]);
        argc++;
    }
    return cmd;
}

int pbpaste(int argc, char** argv) {
    if (currentSession == NULL) {
        currentSession = [[sessionParameters alloc] init];
    }
    // We can paste strings and URLs.
    if ([UIPasteboard generalPasteboard].hasStrings) {
        fprintf(currentSession.stdout, "%s", [[UIPasteboard generalPasteboard].string UTF8String]);
        if (![[UIPasteboard generalPasteboard].string hasSuffix:@"\n"]) fprintf(currentSession.stdout, "\n");
        return 0;
    }
    if ([UIPasteboard generalPasteboard].hasURLs) {
        fprintf(currentSession.stdout, "%s\n", [[[UIPasteboard generalPasteboard].URL absoluteString] UTF8String]);
        return 0;
    }
    return 1;
}


int pbcopy(int argc, char** argv) {
    if (argc == 1) {
        // no arguments, listen to stdin
        if (currentSession == NULL) {
            currentSession = [[sessionParameters alloc] init];
        }
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
        // threre are arguments, concatenate and paste:
        char* cmd = concatenateArgv(argv + 1);
        [UIPasteboard generalPasteboard].string = @(cmd);
        free(cmd);
    }
    return 0;
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
    // TODO: save the environment (HOW?) and current dir
    // TODO: replace environment with envp. envp looks a lot like current environment, though.
    int returnValue = ios_execv(path, argv);
    // TODO: restore the environment (HOW?)
    return returnValue;
}

const pthread_t ios_getLastThreadId() {
    if (!currentSession) return nil;
    return (currentSession.lastThreadId);
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
            case 0: child_stdin = stream1; return fd2;
            case 1: child_stdout = stream1; return fd2;
            case 2: child_stderr = stream1; return fd2;
        }
    }
    if (fd2 == 0) { child_stdin = fdopen(fd1, "rb"); }
    else if (fd2 == 1) { child_stdout = fdopen(fd1, "wb"); }
    else if (fd2 == 2) {
        if (fileno(child_stdout) == fd1) child_stderr = child_stdout;
        else child_stderr = fdopen(fd1, "wb"); }
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

int ios_kill()
{
    if (currentSession == NULL) return ESRCH;
    if (currentSession.current_command_root_thread > 0) {
        // Send pthread_kill with the given signal to the current main thread, if there is one.
        return pthread_cancel(currentSession.current_command_root_thread);
    }
    // No process running
    return ESRCH;
}

void ios_switchSession(void* sessionId) {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    id sessionKey = [NSNumber numberWithInt:((int)sessionId)];
    if (sessionList == nil) {
        sessionList = [NSMutableDictionary new];
        if (currentSession != NULL) [sessionList setObject: currentSession forKey: sessionKey];
    }
    currentSession = [sessionList objectForKey: sessionKey];
    if (currentSession == NULL) {
        currentSession = [[sessionParameters alloc] init];
        [sessionList setObject: currentSession forKey: sessionKey];
    } else {
        if (![currentSession.currentDir isEqualToString:[fileManager currentDirectoryPath]])
            [fileManager changeCurrentDirectoryPath:currentSession.currentDir];
        currentSession.stdin = stdin;
        currentSession.stdout = stdout;
        currentSession.stderr = stderr;
    }
}

void ios_setDirectoryURL(NSURL* workingDirectoryURL) {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager changeCurrentDirectoryPath:[workingDirectoryURL path]];
    if (currentSession != NULL) {
        if ([currentSession.currentDir isEqualToString:[fileManager currentDirectoryPath]]) return;
        currentSession.previousDirectory = currentSession.currentDir;
        currentSession.currentDir = [workingDirectoryURL path];
    }
}

void ios_closeSession(void* sessionId) {
    // delete information associated with current session:
    if (sessionList == nil) return;
    id sessionKey = [NSNumber numberWithInt:((int)sessionId)];
    [sessionList removeObjectForKey: sessionKey];
    currentSession = NULL;
}

int ios_isatty(int fd) {
    if (currentSession == NULL) return 0;
    // 2 possibilities: 0, 1, 2 (classical) or fileno(thread_stdout)
    if ((fd == STDIN_FILENO) || (fd == fileno(currentSession.stdin)) || (fd == fileno(thread_stdin)))
        return (fileno(thread_stdin) == fileno(currentSession.stdin));
    if ((fd == STDOUT_FILENO) || (fd == fileno(currentSession.stdout)) || (fd == fileno(thread_stdout)))
        return (fileno(thread_stdout) == fileno(currentSession.stdout));
    if ((fd == STDERR_FILENO) || (fd == fileno(currentSession.stderr)) || (fd == fileno(thread_stderr)))
        return (fileno(thread_stderr) == fileno(currentSession.stderr));
    return 0;
}

void ios_setStreams(FILE* _stdin, FILE* _stdout, FILE* _stderr) {
    if (currentSession == NULL) return;
    currentSession.stdin = _stdin;
    currentSession.stdout = _stdout;
    currentSession.stderr = _stderr;
}

void ios_setContext(void *context) {
    if (currentSession == NULL) return;
    currentSession.context = context;
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
    if (!function) return; // if not, we don't replace.
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
    commandList = [mutableDict mutableCopy];
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
    if ([locationURL checkResourceIsReachableAndReturnError:&error] == NO) return error;

    NSData* dataLoadedFromFile = [NSData dataWithContentsOfFile:fileLocation  options:0 error:&error];
    if (!dataLoadedFromFile) return error;
    NSDictionary* newCommandList = [NSPropertyListSerialization propertyListWithData:dataLoadedFromFile options:NSPropertyListImmutable format:NULL error:&error];
    if (!newCommandList) return error;
    // merge the two dictionaries:
    NSMutableDictionary *mutableDict = [commandList mutableCopy];
    [mutableDict addEntriesFromDictionary:newCommandList];
    commandList = [mutableDict mutableCopy];
    return NULL;
}


NSString* commandsAsString() {
    
    if (commandList == nil) initializeCommandList();
    
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:commandList.allKeys options:0 error:&err];
    NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return myString;
}

NSArray* commandsAsArray() {
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
    if (strlen(argument) == 0) return NULL; // be safe
    if (argument[0] == '"') {
        char* endquote = nextUnescapedCharacter(argument + 1, '"');
        if (endquote != NULL) return endquote + 1;
        else return NULL;
    } else if (argument[0] == '\'') {
        char* endquote = nextUnescapedCharacter(argument + 1, '\'');
        if (endquote != NULL) return endquote + 1;
        else return NULL;
    }
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

int ios_system(const char* inputCmd) {
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

    if (currentSession == NULL) {
        currentSession = [[sessionParameters alloc] init];
    }
    
    // initialize:
    if (thread_stdin == 0) thread_stdin = currentSession.stdin;
    if (thread_stdout == 0) thread_stdout = currentSession.stdout;
    if (thread_stderr == 0) thread_stderr = currentSession.stderr;
    if (thread_context == 0) thread_context = currentSession.context;

    char* cmd = strdup(inputCmd);
    char* maxPointer = cmd + strlen(cmd);
    char* originalCommand = cmd;
    // fprintf(thread_stderr, "Command sent: %s \n", cmd); fflush(stderr);
    if (cmd[0] == '"') {
        // Command was enclosed in quotes (almost always with Vim)
        char* endCmd = strstr(cmd + 1, "\""); // find closing quote
        if (endCmd) {
            cmd = cmd + 1; // remove starting quote
            endCmd[0] = 0x0;
            assert(endCmd < maxPointer);
        }
        // assert(cmd + strlen(cmd) < maxPointer);
    }
    if (cmd[0] == '(') {
        // Standard vim encoding: command between parentheses
        command = cmd + 1;
        char* endCmd = strstr(command, ")"); // remove closing parenthesis
        if (endCmd) {
            endCmd[0] = 0x0;
            assert(endCmd < maxPointer);
            inputFileMarker = endCmd + 1;
        }
    } else command = cmd;
    // fprintf(thread_stderr, "Command sent: %s \n", command);
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
    params->context = thread_context;
  
    child_stdin = child_stdout = child_stderr = NULL;
    params->argc = 0; params->argv = 0; params->argv_ref = 0;
    params->function = NULL; params->isPipeOut = false; params->isPipeErr = false;
    // scan until first "<" (input file)
    inputFileMarker = strstr(inputFileMarker, "<");
    // scan until first non-space character:
    if (inputFileMarker) {
        inputFileName = inputFileMarker + 1; // skip past '<'
        // skip past all spaces
        while ((inputFileName[0] == ' ') && strlen(inputFileName) > 0) inputFileName++;
    }
    // is there a pipe ("|", "&|" or "|&")
    // We assume here a logical command order: < before pipe, pipe before >.
    // TODO: check what happens for unlogical commands. Refuse them, but gently.
    // TODO: implement tee, because that has been removed
    char* pipeMarker = strstr (outputFileMarker,"&|");
    if (!pipeMarker) pipeMarker = strstr (outputFileMarker,"|&"); // both seem to work
    if (pipeMarker) {
        bool pushMainThread = currentSession.isMainThread;
        currentSession.isMainThread = false;
        params->stdout = params->stderr = ios_popen(pipeMarker+2, "w");
        currentSession.isMainThread = pushMainThread;
        pipeMarker[0] = 0x0;
        sharedErrorOutput = true;
    } else {
        pipeMarker = strstr (outputFileMarker,"|");
        if (pipeMarker) {
            bool pushMainThread = currentSession.isMainThread;
            currentSession.isMainThread = false;
            params->stdout = ios_popen(pipeMarker+1, "w");
            currentSession.isMainThread = pushMainThread;
            pipeMarker[0] = 0x0;
        }
    }
    // We have removed the pipe part. Still need to parse the rest of the command
    // Must scan in strstr by reverse order of inclusion. So "2>&1" before "2>" before ">"
    errorFileMarker = strstr (outputFileMarker,"&>"); // both stderr/stdout sent to same file
    // output file name will be after "&>"
    if (errorFileMarker) { outputFileName = errorFileMarker + 2; outputFileMarker = errorFileMarker; }
    if (!errorFileMarker) {
        // TODO: 2>&1 before > means redirect stderr to (current) stdout, then redirects stdout
        // ...except with a pipe.
        // Currently, we don't check for that.
        errorFileMarker = strstr (outputFileMarker,"2>&1"); // both stderr/stdout sent to same file
        if (errorFileMarker) {
            if (params->stdout) params->stderr = params->stdout;
            outputFileMarker = strstr(outputFileMarker, ">");
            if (outputFileMarker) outputFileName = outputFileMarker + 1; // skip past '>'
        }
    }
    if (errorFileMarker) { sharedErrorOutput = true; }
    else {
        // specific name for error file?
        errorFileMarker = strstr(outputFileMarker,"2>");
        if (errorFileMarker) {
            errorFileName = errorFileMarker + 2; // skip past "2>"
            // skip past all spaces:
            while ((errorFileName[0] == ' ') && strlen(errorFileName) > 0) errorFileName++;
        }
    }
    // scan until first ">"
    if (!sharedErrorOutput) {
        outputFileMarker = strstr(outputFileMarker, ">");
        if (outputFileMarker) outputFileName = outputFileMarker + 1; // skip past '>'
    }
    if (outputFileName) {
        while ((outputFileName[0] == ' ') && strlen(outputFileName) > 0) outputFileName++;
    }
    if (errorFileName && (outputFileName == errorFileName)) {
        // we got the same ">" twice, pick the next one ("2>" was before ">")
        outputFileMarker = errorFileName;
        outputFileMarker = strstr(outputFileMarker, ">");
        if (outputFileMarker) {
            outputFileName = outputFileMarker + 1; // skip past '>'
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
    // Must be done after the parsing
    if (inputFileMarker) inputFileMarker[0] = 0x0;
    if (outputFileMarker && (params->stdout == NULL)) outputFileMarker[0] = 0x0;
    if (errorFileMarker) errorFileMarker[0] = 0x0;
    // strip filenames of quotes, if any:
    if (outputFileName) outputFileName = unquoteArgument(outputFileName);
    if (inputFileName) inputFileName = unquoteArgument(inputFileName);
    if (errorFileName) errorFileName = unquoteArgument(errorFileName);
    //
    FILE* newStream;
    if (inputFileName) {
        newStream = fopen(inputFileName, "r");
        if (newStream) params->stdin = newStream;
    }
    if (params->stdin == NULL) params->stdin = thread_stdin;
    if (outputFileName) {
        newStream = fopen(outputFileName, "w");
        if (newStream) params->stdout = newStream; // open did not work
    }
    if (params->stdout == NULL) params->stdout = thread_stdout;
    if (sharedErrorOutput) params->stderr = params->stdout;
    else if (errorFileName) {
        newStream = NULL;
        newStream = fopen(errorFileName, "w");
        if (newStream) params->stderr = newStream; // open did not work
    }
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
        char* end = getLastCharacterOfArgument(str);
        bool mustBreak = (end == NULL) || (strlen(end) == 0);
        if (!mustBreak) end[0] = 0x0;
        if ((str[0] == '\'') || (str[0] == '"')) {
            dontExpand[argc-1] = true; // don't expand arguments in quotes
        }
        argv[argc-1] = unquoteArgument(argv[argc-1]);
        if (mustBreak) break;
        str = end + 1;
        if ((argc == 1) && (argv[0][0] == '/') && (access(argv[0], R_OK) == -1)) {
            // argv[0] is a file that doesn't exist. Probably one of our commands.
            // Replace with its name:
            char* newName = basename(argv[0]);
            argv[0] = realloc(argv[0], strlen(newName));
            strcpy(argv[0], newName);
        }
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
            if (strstr (argv[i],"*") || strstr (argv[i],"?") || strstr (argv[i],"[")) {
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
                    fprintf(thread_stderr, "%s: %s: No match\n", argv[0], argv[i]);
                    fflush(thread_stderr);
                    globfree(&gt);
                    free(dontExpand);
                    free(argv);
                    free(originalCommand);
                    return 127;
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
            size_t len_with_terminator = strlen(argv[0] + 1) + 1;
            memmove(argv[0], argv[0] + 1, len_with_terminator);
        } else  {
            NSString* commandName = [NSString stringWithCString:argv[0]  encoding:NSUTF8StringEncoding];
            currentSession.commandName = commandName;
            BOOL isDir = false;
            BOOL cmdIsAFile = false;
            bool cmdIsAPath = false;
            if ([commandName hasPrefix:@"~/"]) {
                NSString* replacement_string = [NSString stringWithCString:(getenv("HOME")) encoding:NSUTF8StringEncoding];
                NSString* test_string = @"~";
                commandName = [commandName stringByReplacingOccurrencesOfString:test_string withString:replacement_string options:NULL range:NSMakeRange(0, 1)];
            }
            if ([fileManager fileExistsAtPath:commandName isDirectory:&isDir]  && (!isDir)) {
                // File exists, is a file.
                struct stat sb;
                if ((stat(commandName.UTF8String, &sb) == 0) && S_ISXXX(sb.st_mode)) {
                    // File exists, is executable, not a directory.
                    cmdIsAFile = true;
                }
            }
            // if commandName contains "/", then it's a path, and we don't search for it in PATH.
            cmdIsAPath = ([commandName rangeOfString:@"/"].location != NSNotFound) && !cmdIsAFile;
            if (!cmdIsAPath) {
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
                        // search for 3 possibilities: name, name.bc and name.ll
                        locationName = [path stringByAppendingPathComponent:commandName];
                        bool fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
                        if (fileFound && isDir) continue; // file exists, but is a directory
                        if (!fileFound) {
                            locationName = [[path stringByAppendingPathComponent:commandName] stringByAppendingString:@".bc"];
                            fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
                            if (fileFound && isDir) continue; // file exists, but is a directory
                        }
                        if (!fileFound) {
                            locationName = [[path stringByAppendingPathComponent:commandName] stringByAppendingString:@".ll"];
                            fileFound = [fileManager fileExistsAtPath:locationName isDirectory:&isDir];
                            if (fileFound && isDir) continue; // file exists, but is a directory
                        }
                        if (!fileFound) continue;
                        // isExecutableFileAtPath replies "NO" even if file has x-bit set.
                        // if (![fileManager  isExecutableFileAtPath:cmdname]) continue;
                        struct stat sb;
                        if (!((stat(locationName.UTF8String, &sb) == 0) && S_ISXXX(sb.st_mode))) continue;
                        // File exists, is executable, not a directory.
                    } else
                        // if (cmdIsAFile) we are now ready to execute this file:
                        locationName = commandName;
                    if (([locationName hasSuffix:@".bc"]) || ([locationName hasSuffix:@".ll"])) {
                        // insert lli in front of argument list:
                        argc += 1;
                        argv = (char **)realloc(argv, sizeof(char*) * argc);
                        // Move everything one step up
                        for (int i = argc; i >= 1; i--) { argv[i] = argv[i-1]; }
                        argv[1] = realloc(argv[1], strlen(locationName.UTF8String));
                        strcpy(argv[1], locationName.UTF8String);
                        argv[0] = strdup("lli"); // this one is new
                        break;
                    } else {
                        NSData *data = [NSData dataWithContentsOfFile:locationName];
                        NSString *fileContent = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                        NSRange firstLineRange = [fileContent rangeOfString:@"\n"];
                        if (firstLineRange.location == NSNotFound) firstLineRange.location = 0;
                        firstLineRange.length = firstLineRange.location;
                        firstLineRange.location = 0;
                        NSString* firstLine = [fileContent substringWithRange:firstLineRange];
                        if ([firstLine hasPrefix:@"#!"]) {
                            // So long as the 1st line begins with "#!" and contains "python" we accept it as a python script
                            // "#! /usr/bin/python", "#! /usr/local/bin/python" and "#! /usr/bin/myStrangePath/python" are all OK.
                            // We also accept "#! /usr/bin/env python" because it is used.
                            // TODO: only accept "python" or "python2" at the end of the line
                            // executable scripts files. Python and lua:
                            // 1) get script language name
                            if ([firstLine containsString:@"python"]) {
                                scriptName = "python";
                            } else if ([firstLine containsString:@"lua"]) {
                                scriptName = "lua";
                            }
                            if (scriptName) {
                                // 2) insert script language at beginning of argument list
                                argc += 1;
                                argv = (char **)realloc(argv, sizeof(char*) * argc);
                                // Move everything one step up
                                for (int i = argc; i >= 1; i--) { argv[i] = argv[i-1]; }
                                argv[1] = realloc(argv[1], strlen(locationName.UTF8String));
                                strcpy(argv[1], locationName.UTF8String);
                                argv[0] = strdup(scriptName); // this one is new
                                break;
                            }
                        }
                    }
                    if (cmdIsAFile) break; // else keep going through the path elements.
                }
            }
        }
        // fprintf(thread_stderr, "Command after parsing: ");
        // for (int i = 0; i < argc; i++)
        //    fprintf(thread_stderr, "[%s] ", argv[i]);
        // We've reached this point: either the command is a file, from a script we support,
        // and we have inserted the name of the script at the beginning, or it is a builtin command
        int (*function)(int ac, char** av) = NULL;
        if (commandList == nil) initializeCommandList();
        NSString* commandName = [NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding];
        NSArray* commandStructure = [commandList objectForKey: commandName];
        void* handle = NULL;
        if (commandStructure != nil) {
            NSString* libraryName = commandStructure[0];
            if ([libraryName isEqualToString: @"SELF"]) handle = RTLD_SELF;  // commands defined in ios_system.framework
            else if ([libraryName isEqualToString: @"MAIN"]) handle = RTLD_MAIN_ONLY; // commands defined in main program
            else handle = dlopen(libraryName.UTF8String, RTLD_LAZY | RTLD_GLOBAL); // commands defined in dynamic library
            if (sideLoading && (handle == NULL)) fprintf(thread_stderr, "Failed loading %s from %s, cause = %s\n", commandName.UTF8String, libraryName.UTF8String, dlerror());
            NSString* functionName = commandStructure[1];
            function = dlsym(handle, functionName.UTF8String);
            if (sideLoading && (function == NULL)) fprintf(thread_stderr, "Failed loading %s from %s, cause = %s\n", commandName.UTF8String, libraryName.UTF8String, dlerror());
        }
        if (function) {
            // We run the function in a thread because there are several
            // points where we can exit from a shell function.
            // Commands call pthread_exit instead of exit
            // thread is attached, could also be un-attached
            pthread_t _tid;
            params->argc = argc;
            params->argv = argv;
            params->function = function;
            params->dlHandle = handle;
            params->isPipeOut = (params->stdout != thread_stdout);
            params->isPipeErr = (params->stderr != thread_stderr) && (params->stderr != params->stdout);
            if (currentSession.isMainThread) {
                bool commandOperatesOnFiles = ([commandStructure[3] isEqualToString:@"file"] ||
                                               [commandStructure[3] isEqualToString:@"directory"] ||
                                               params->isPipeOut || params->isPipeErr);
                NSString* currentPath = [fileManager currentDirectoryPath];
                commandOperatesOnFiles &= (currentPath != nil); 
                if (commandOperatesOnFiles) {
                    // Send a signal to the system that we're going to change the current directory:
                    // TODO: only do this if the command actually accesses files: either outputFile exists,
                    // or errorFile exists, or the command uses files.
                    NSURL* currentURL = [NSURL fileURLWithPath:currentPath];
                    NSFileCoordinator *fileCoordinator =  [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                    [fileCoordinator coordinateWritingItemAtURL:currentURL options:0 error:NULL byAccessor:^(NSURL *currentURL) {
                        currentSession.isMainThread = false;
                        pthread_create(&_tid, NULL, run_function, params);
                        currentSession.current_command_root_thread = _tid;
                        // Wait for this process to finish:
                        pthread_join(_tid, NULL);
                        // If there are auxiliary process, also wait for them:
                        if (currentSession.lastThreadId > 0) pthread_join(currentSession.lastThreadId, NULL);
                        currentSession.lastThreadId = 0;
                        currentSession.current_command_root_thread = 0;
                        currentSession.isMainThread = true;
                    }];
                } else {
                    currentSession.isMainThread = false;
                    pthread_create(&_tid, NULL, run_function, params);
                    currentSession.current_command_root_thread = _tid;
                    // Wait for this process to finish:
                    pthread_join(_tid, NULL);
                    // If there are auxiliary process, also wait for them:
                    if (currentSession.lastThreadId > 0) pthread_join(currentSession.lastThreadId, NULL);
                    currentSession.lastThreadId = 0;
                    currentSession.current_command_root_thread = 0;
                    currentSession.isMainThread = true;
                }
            } else {
                // Don't send signal if not in main thread. Also, don't join threads.
                pthread_create(&_tid, NULL, run_function, params);
                // The last command on the command line (with multiple pipes) will be created first
                if (currentSession.lastThreadId == 0) currentSession.lastThreadId = _tid;
            }
        } else {
            fprintf(thread_stderr, "%s: command not found\n", argv[0]);
            free(argv);
            // If command output was redirected to a pipe, we still need to close it.
            // (to warn the other command that it can stop waiting)
            if (params->stdout != thread_stdout) {
                fclose(params->stdout);
            }
            if ((params->stderr != thread_stderr) && (params->stderr != params->stdout)) {
                fclose(params->stderr);
            }
            if ((handle != NULL) && (handle != RTLD_SELF)
                && (handle != RTLD_MAIN_ONLY)
                && (handle != RTLD_DEFAULT) && (handle != RTLD_NEXT))
                dlclose(handle);
            free(params); // This was malloc'ed in ios_system
            currentSession.global_errno = 127;
            // TODO: this should also raise an exception, for python scripts
        } // if (function)
    } else { // argc != 0
        free(argv); // argv is otherwise freed in cleanup_function
    }
    free(originalCommand); // releases cmd, which was a strdup of inputCommand
    fflush(thread_stdout);
    fflush(thread_stderr);
    return currentSession.global_errno;
}
