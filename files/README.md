# files: command for processing files

Swift package for all commands for processing files: chflags, chmod, chown, cksum, compress, cp, df, du, gzip, less, ln, ls, mkdir, mv, rm, rmdir, stat, touch.

This package depends on the `ios_system` package (also included in this repository).

The `ios_error.h` file was copied from `ios_system` (because C compilers have issues with loading files from inside a package). 
TODO: make it a resource downloaded from the repository (will require the next version of Xcode, currently in beta).   
