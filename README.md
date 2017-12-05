# ios_system: Drop-in replacement for system() in iOS programs

When porting Unix utilities to iOS (vim, TeX, python...), sometimes the source code executes system commands, using `system()` calls. These calls are rejected at compile time, with: 
`error: 'system' is unavailable: not available on iOS`. 

This project provides a drop-in replacement for `system()`. Simply add the following lines at the beginning of you header file: 
```cpp
extern int ios_system(char* cmd);
#define system ios_system
```
and your calls to system will be handled by the project.

The commands available are defined in `ios_system.m`. They are configurable through a series of `#define`. 

There are, first, shell commands (`ls`, `cp`, `rm`...), archive commands (`tar`, `gz`, `compress`...) plus a few interpreted languages (`python`, `lua`, `TeX`). Scripts written in one of the interpreted languages are also executed, if they are in the `$PATH`. 

For each set of commands, we need to provide the associated framework. Frameworks for small commands are in this project. Frameworks for interpreted languages are larger, and available separately: 
