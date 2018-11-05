# ios_system: Drop-in replacement for system() in iOS programs


<p align="center">
<img src="https://img.shields.io/badge/Platform-iOS%2010.0+-lightgrey.svg" alt="Platform: iOS">
<a href="https://travis-ci.org/holzschu/ios_system"><img src="https://travis-ci.org/holzschu/ios_system.svg?branch=master" alt="Build Status"/></a>
<br>
<a href="http://twitter.com/nholzschuch"><img src="https://img.shields.io/badge/Twitter-@nholzschuch-blue.svg?style=flat" alt="Twitter"/></a>
</p>


When porting Unix utilities to iOS (vim, TeX, python...), sometimes the source code executes system commands, using `system()` calls. These calls are rejected at compile time, with: 
`error: 'system' is unavailable: not available on iOS`. 

This project provides a drop-in replacement for `system()`. Simply add the following lines at the beginning of you header file: 
```cpp
extern int ios_system(char* cmd);
#define system ios_system
```
link with the `ios_system.framework`, and your calls to `system()` will be handled by this framework.

**Commands available:** shell commands (`ls`, `cp`, `rm`...), archive commands (`curl`, `scp`, `sftp`, `tar`, `gzip`, `compress`...) plus a few interpreted languages (`python`, `lua`, `TeX`). Scripts written in one of the interpreted languages are also executed, if they are in the `$PATH`. 

The commands available are defined in two dictionaries, `Resources/commandDictionary.plist` and `Resources/extraCommandsDictionary.plist`. At startup time, `ios_system` loads these dictionaries and enables the commands defined inside. You will need to add these two dictionaries to the "Copy Bundle Resources" step in your Xcode project.

Each command is defined inside a framework. The framework is loaded when the command is called, and released after the command exits. Frameworks for small commands are in this project. Frameworks for interpreted languages are larger, and available separately: [python](https://github.com/holzschu/python_ios), [lua](https://github.com/holzschu/lua_ios) and [TeX](https://github.com/holzschu/lib-tex). Some commands (`curl`, `python`) require `OpenSSH` and `libssl2`, which you will have to download and compile separately (see https://github.com/holzschu/libssh2-for-iOS, for example).

Network-based commands (nslookup, dig, host, ping, telnet) are also available as a separate framework, [network_ios](https://github.com/holzschu/network_ios). Place the compiled library with the other libraries and add it to the embedded libraries of your application.

This `ios_system` framework has been successfully integrated into four shells, [Blink](https://github.com/blinksh/blink/), [OpenTerm](https://github.com/louisdh/terminal), [Pisth](https://github.com/ColdGrub1384/Pisth) and [LibTerm](https://github.com/ColdGrub1384/LibTerm) as well as an editor, [iVim](https://github.com/holzschu/iVim). Each time, it provides a Unix look-and-feel (well, mostly feel). 

**Issues:** In iOS, you cannot write in the `~` directory, only in `~/Documents/`, `~/Library/` and `~/tmp`. Most Unix programs assume the configuration files are in `$HOME`. 
So either you redefine `$HOME` to `~/Documents/` or you set configuration variables (using `setenv`) to some other place. This is done in the `initializeEnvironment()` function. 

Here's what I have:
```powershell
setenv PATH = $PATH:~/Library/bin:~/Documents/bin
setenv PYTHONHOME = $HOME/Library/
setenv SSH_HOME = $HOME/Documents/
setenv CURL_HOME = $HOME/Documents/
setenv HGRCPATH = $HOME/Documents/.hgrc/
setenv SSL_CERT_FILE = $HOME/Documents/cacert.pem
```
Your Mileage May Vary. Note that iOS already defines `$HOME` and `$PATH`. 

## scp and sftp:

`scp`and `sftp` are implemented by rewriting them as `curl` commands. For example, `scp user@host:~/distantfile localfile` becomes (internally) `curl scp://user@host/~/distantFile -o localFile`. This was done to keep the size of the framework as small as possible. It will work for most of the users and most of the commands. However, it has consequences:
- `scp` from distant file to distant file probably won't work, only from local to distant or distant to local. 
- The flags are those from `curl`, not `scp`. Except `-q` (quiet) which I remapped to `-s` (silent). 
- The config file is `.curlrc`, not `.ssh/config`. 
- The library used internally is `libssh2`, not `OpenSSH`.


## Installation:

**The easy way:** run the script `./get_binaries.sh`. This will download the compiled versions of all existing frameworks (`ios_system.framework`, plus all the frameworks libraries, including `network_ios`). 

**The hard way:**

- Run the script `./get_sources.sh`. This will download the latest sources form [Apple OpenSource](https://opensource.apple.com) and patch them for compatibility with iOS. 
- We need libSSH2 and OpenSSL. Either: 
    - **[Fast]** Run the script `./get_frameworks.sh` to download precompiled versions of `openSSL.framework` and `libSSH2.framework`.
    - **[Slow]** Run the script `./get_frameworks_as_source.sh` to download the source for  `openSSL.framework` and `libSSH2.framework`, compile them, and move them to `Frameworks`. 
- Open the Xcode project `ios_system.xcodeproj` and hit build. This will create the `ios_system` framework, ready to be included in your own projects. 
- Compile the other targets as well: files, tar, curl, awk, shell, text, ssh_cmd. This will create the corresponding frameworks.
- Alternatively, type `xcodebuild -project ios_system.xcodeproj -alltargets -sdk iphoneos -configuration Debug -quiet` to build all targets.
- If you need [python](https://github.com/holzschu/python_ios), [lua](https://github.com/holzschu/lua_ios), [TeX](https://github.com/holzschu/lib-tex) or [network_ios](https://github.com/holzschu/network_ios), download the corresponding projects and compile them. All these projects need the `ios_system` framework to compile.

## Integration with your app:

- Link your application with the `ios_system.framework` framework.
- Embed (but don't link) the frameworks corresponding to the commands you need (`libtar.dylib` if you need `tar`, `libfiles.dylib` for cp, rm, mv...). 
- Add the two dictionaries, `Resources/commandDictionary.plist` and `Resources/extraCommandsDictionary.plist` to the  "Copy Bundle Resources" step in your Xcode project.

### Basic commands:

The simplest way to integrate `ios_system` into your app is to just replace all calls to `system()` with calls to `ios_system()`. If you need more control and information, the following functions are available: 

- `initializeEnvironment()` sets environment variables to sensible defaults. 
- `ios_executable(char* inputCmd)` returns true if `inputCmd` is one of the commands defined inside `ios_system`. 
- `NSArray* commandsAsArray()` returns an array with all the commands available, if you need them for helping users. 
- `NSString* commandsAsString()` same, but with a `NSString*`. 
- `NSString* getoptString(NSString* command)` returns a string containing all accepted flags for a given command ("dfiPRrvW" for "rm", for example). Letters are followed by ":" if the flag cannot be combined with others. 
- `NSString* operatesOn(NSString* command)` tells you what this command expects as arguments, so you can auto-complete accordingly. Return values are "file", "directory" or "no". For example, "cd" returns "directory". 
- `int ios_setMiniRoot(NSString* mRoot)` lets you set the sandbox directory, so users are not exposed to files outside the sandbox. The argument is the path to a directory. It will not be possible to `cd` to directories above this one. Returns 1 if succesful, 0 if not. 
- `FILE* ios_popen(const char* inputCmd, const char* type)` opens a pipe between the current command and `inputCmd`. (drop-in replacement for `popen`). 

### More advance control: 

**replaceCommand**: `replaceCommand(NSString* commandName, int (*newFunction)(int argc, char *argv[]), bool allOccurences)` lets you replace an existing command implementation with your own, or add new commands without editing the source. 

Sample use: `replaceCommand(@"ls", gnu_ls_main, true);`: Replaces all calls to `ls` to calls to `gnu_ls_main`. The last argument tells whether you want to replace only the function associated with `ls` (if `false`) or all the commands that used the function previously associated with `ls`(if true). For example, `compress` and `uncompress` are both done with the same function, `compress_main` (and the actual behaviour depends on `argv[0]`). Only you can know whether your replacement function handles both roles, or only one of them. 

If the command does not already exist, your command is simply added to the list. 

**addCommandList:** `NSError* addCommandList(NSString* fileLocation)` loads several commands at once, and adds them to the list of existing commands. `fileLocation` points to a plist file, with the same syntax as  `Resources/extraCommandsDictionary.plist`: the key is the command name, and is followed by an Array of 4 Strings: name of the framework, name of the function to call, list of options (in `getopt()` format) and what the command expects as argument (file, directory, nothing). The last two can be used for autocomplete. The name of the framework can be `MAIN` if your command is defined in your main program (equivalent to the `RTLD_MAIN_ONLY` option for `dlsym()`), or `SELF` if it is defined inside `ios_system.framework` (equivalent to `RTLD_SELF`). 

Example: 
```xml
<key>rlogin</key>
  <array>
    <string>network_ios.framework/network_ios</string>
    <string>rlogin_main</string>
    <string>468EKLNS:X:acde:fFk:l:n:rs:uxy</string>
    <string>no</string>
  </array>
```

**ios_execv(const char *path, char* const argv[])**: executes the command in `argv[0]` with the arguments `argv` (it doesn't use `path`). It is *not* a drop-in replacement for `execv` because it does not terminate the current process. `execv` is usually called after `fork()`, and `execv` terminates the child process. This is not possible in iOS. If `dup2` was called before `execv` to set stdin and stdout, `ios_execv` tries to do the right thing and pass these streams to the process started by `execv`. 

`ios_execve` also exists, but is just a pointer to `ios_execv` (we don't do anything with the environment for now). 

## Adding more commands:

`ios_system` is OpenSource; you can extend it in any way you want. Keep in mind the intrinsic limitations: 
- Sandbox and API limitations still apply. Commands that require root privilege (like `traceroute`) are impossible.
- Inside terminals we have limited interaction. Apps that require user input are unlikely to get it, or with no visual feedback. That could be solved, but it is hard.

To add a command:
- (Optional) create an issue: https://github.com/holzschu/ios_system/issues That will let others know you're working on it, and possibly join forces with you (that's the beauty of OpenSource). 
- find the source code for the command, preferrably with BSD license. [Apple OpenSource](https://opensource.apple.com) is a good place to start. Compile it first for OSX, to see if it works, and go through configuration. 
- make the following changes to the code: 
    - change the `main()` function into `command_main()`.
    - include `ios_error.h`.
    - link with `ios_system.framework`; this will replace most function calls by `ios_system` version (`exit`, `warn`, `err`, `errx`, `warnx`, `printf`, `write`...)
    - replace calls to `isatty()` with calls to `ios_isatty()`. 
    - usually, this is enough for your command to compile, and sometimes to run. Check that it works.
    - if you have no output: find where the output happens. Within `ios_system`, standard output must go to `thread_stout`. `libc_replacement.c` intercepts most of the output functions, but not all.
    - if you have issues with input: find where it happens. Standard input comes from `thread_stdin`.
    - make sure you initialize all variables at startup, and release all memory on exit.
    - make all global variables thread-local with `__thread`, make sure local variables are marked with `static`. 
    - make sure your code doesn't use commands that don't work in a sandbox: `fork`, `exec`, `system`, `popen`, `isExecutableFileAtPath`, `access`... (some of these fail at compile time, others fail silently at run time). 
    - compile the digital library, add it to the embedded frameworks of your app. 
    - Edit the `Resources/extraCommandsDictionary.plist` to add your command, and run. 
    - That's it. 
    - Test a lot. Side effects can appear after several launches.
    - if your command has a large code base, work out the difference in your edits and make a patch, rather than commit the entire code. See `get_sources_for_patching.sh` for an example. 

**Frequently asked commands:** here is a list of commands that are often requested, and my experience with them:
- `ping`, `nslookup`, `telnet`: now provided in the [network_ios](https://github.com/holzschu/network_ios) package.
- `traceroute` and most network analysis tools: require root privilege, so impossible inside a sandbox.
- `unzip`: use `tar -xz`. 
- `nano`, `ed`: require user interaction, so currently impossible.
- `vim`: like `ed`, but even more difficult (needs to access the entire screen, need to add lines to the keyboard for Escape, Tab... iVim is on the App Store, and can be accessed from inside OpenTerm using the `share` command. My fork of [iVim](https://github.com/holzschu/iVim) can launch shell commands with `:!`. It's easier to make an editor start commands than to make a terminal run an editor.
- `sh`, `bash`, `zsh`: shells are hard to compile, even without the sandbox/API limitations. They also tend to take a lot of memory, which is a limited asset.
- `git`: [WorkingCopy](https://workingcopyapp.com) does it very well, and you can transfer directories to your app, then transfer back to WorkingCopy. Also difficult to compile. 


### Licensing:

`ios_system` itself is released under the  <a href='https://en.wikipedia.org/wiki/BSD_licenses#3-clause_license_("BSD_License_2.0",_"Revised_BSD_License",_"New_BSD_License",_or_"Modified_BSD_License")'>Revised BSD License</a> (3-clause BSD license). Foe the other tools, I've used the BSD version as often as possible: 
- awk: <a href="https://github.com/onetrueawk/awk/blob/master/LICENSE">OpenSource license</a>.
- curl, scp, sftp: <a href="https://curl.haxx.se/docs/copyright.html">MIT/X derivate license</a>.
- lua: <a href="https://www.lua.org/license.html">MIT License</a>.
- python: <a href="https://docs.python.org/2.7/license.html">Python license</a>.
- libssh2: <a href='https://en.wikipedia.org/wiki/BSD_licenses#3-clause_license_("BSD_License_2.0",_"Revised_BSD_License",_"New_BSD_License",_or_"Modified_BSD_License")'>Revised BSD License</a> (a.k.a. 3-clause BSD license).
- egrep, fgrep, grep, gzip, gunzip, cat, chflag, compress, cp, date, echo, env, link, ln, printenv, pwd, ed, sed, tar, uncompress, uptime, chgrp, chksum, chmod, chown, df, du, groups, id, ls, mkdir, mv, readlink, rm, rmdir, stat, sum, touch, tr, uname, wc, whoami: <a href='https://en.wikipedia.org/wiki/BSD_licenses#3-clause_license_("BSD_License_2.0",_"Revised_BSD_License",_"New_BSD_License",_or_"Modified_BSD_License")'>Revised BSD License</a> (a.k.a. 3-clause BSD license).
- pdftex, luatex and all TeX-based programs: <a href="https://www.gnu.org/licenses/gpl.html">GNU General Public License</a>.

Using BSD versions has consequences on the flags and how they work. For example, there are two versions of `sed`, the BSD version and the GNU version. They have roughly the same behaviour, but differ on `-i` (in place): the GNU version overwrites the file if you don't provide an extension, the BSD version won't work unless you provide the extension to use on the backup file (and will backup the input file with that extension). 
