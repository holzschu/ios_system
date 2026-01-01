//
//  wasm3.c
//  shell
//
//  Created by Nicolas Holzschuch on 22/07/2024.
//  Copyright © 2024 Nicolas Holzschuch. All rights reserved.
//

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
#include <ctype.h>

#include "wasm3.h"
#include "m3_api_libc.h"
#include "m3_api_wasi.h"
#define LINK_WASI

// TODO: remove m3_env.h
#include "m3_env.h"
#include "ios_error.h"

#define ARGV_SHIFT()  { argc--; argv++; }

static const char* modname_from_fn(const char* fn)
{
    const char* sep = "/\\:*?";
    char c;
    while ((c = *sep++)) {
        const char* off = strrchr(fn, c) + 1;
        fn = (fn < off) ? off : fn;
    }

    return fn;
}

int wasm3(int argc, char** argv) {
    unsigned argStackSize = 256*1024;
    if (argc < 2) {
        fprintf(thread_stderr, "Usage: wasm3 command arguments\n"); fflush(thread_stderr);
        return 1;
    }
    FILE* f = fopen (argv[1], "rb");
    if (!f) {
        fprintf(thread_stderr, "%s: No such file %s\n", argv[0], argv[1]); fflush(thread_stderr);
        errno = ENOENT;
        return 1;
    }

    ARGV_SHIFT(); // Skip executable name
    M3Result result = m3Err_none;
    IM3Environment env = m3_NewEnvironment ();
    IM3Runtime runtime = m3_NewRuntime (env, argStackSize, NULL);
    IM3Module module = NULL;
    // load module:
    fseek (f, 0, SEEK_END);
    u32 fsize = ftell(f);
    fseek (f, 0, SEEK_SET);
    if (fsize == 0) {
        fprintf(thread_stderr, "%s: empty file.\n", argv[0]); fflush(thread_stderr);
        errno = ENOENT;
        return 1;
    }
    u8* wasm = (u8*) malloc(fsize);
    int val = fread (wasm, 1, fsize, f);
    if ((val != fsize) || ferror(f)) {
        fprintf(thread_stderr, "%s: could not read file.\n", argv[0]); fflush(thread_stderr);
        free(wasm);
        errno = ENOENT;
        return 1;
    }
    fclose(f);
    f = NULL;
    result = m3_ParseModule (env, &module, wasm, fsize);
    if (result || (module == NULL)) {
        fprintf(thread_stderr, "%s: could not parse WebAssembly: %s.\n", argv[0], result); fflush(thread_stderr);
        if (wasm) free(wasm);
        m3_FreeRuntime (runtime);
        m3_FreeEnvironment (env);
        return 1;
    }
    result = m3_LoadModule (runtime, module);
    if (result || (module == NULL)) {
        fprintf(thread_stderr, "%s: could not load WebAssembly: %s.\n", argv[0], result); fflush(thread_stderr);
        if (wasm) free(wasm);
        m3_FreeRuntime (runtime);
        m3_FreeEnvironment (env);
        return 1;
    }
    m3_SetModuleName(module, modname_from_fn(argv[0]));
    // link module:
    result = m3_LinkSpecTest (module);
    if (result) {
        fprintf(thread_stderr, "%s: could not link with SpecTest: %s.\n", argv[0], result); fflush(thread_stderr);
        if (wasm) free(wasm);
        m3_FreeRuntime (runtime);
        m3_FreeEnvironment (env);
        return 1;
    }
    result = m3_LinkLibC (module);
    if (result) {
        fprintf(thread_stderr, "%s: could not link with libc: %s.\n", argv[0], result); fflush(thread_stderr);
        if (wasm) free(wasm);
        m3_FreeRuntime (runtime);
        m3_FreeEnvironment (env);
        return 1;
    }
    result = m3_LinkWASI (module);
    if (result) {
        fprintf(thread_stderr, "%s: could not link with Wasi: %s.\n", argv[0], result); fflush(thread_stderr);
        if (wasm) free(wasm);
        m3_FreeRuntime (runtime);
        m3_FreeEnvironment (env);
        return 1;
    }
    // call function:
    IM3Function func;
    m3_FindFunction (&func, runtime, "_start");
    // Strip wasm file path
    if (argc > 0) {
        argv[0] = modname_from_fn(argv[0]);
    }
    m3_wasi_context_t* wasi_ctx = m3_GetWasiContext();
    wasi_ctx->argc = argc;
    wasi_ctx->argv = argv;
    result = m3_CallArgv(func, 0, NULL);

    if (result == m3Err_trapExit) {
        if (wasm) free(wasm);
        m3_FreeRuntime (runtime);
        m3_FreeEnvironment (env);
        ios_exit(wasi_ctx->exit_code);
    }
    if (result) {
        fprintf (thread_stderr, "Error: %s", result);
        if (runtime)
        {
            M3ErrorInfo info;
            m3_GetErrorInfo (runtime, &info);
            if (strlen(info.message)) {
                fprintf (thread_stderr, " (%s)", info.message);
            }
        }
        fprintf (thread_stderr, "\n");
    }
    // cleanup:
    if (wasm) free(wasm);
    m3_FreeRuntime (runtime);
    m3_FreeEnvironment (env);
    return result ? 1 : 0;
}
