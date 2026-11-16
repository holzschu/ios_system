/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (c) 1983, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


/* Stream loops adapted from Apple text_cmds/bintrans/{uuencode,uudecode}.c.
 * https://github.com/apple-oss-distributions/text_cmds/tree/main/bintrans
 * Use the system resolver codec; keep command state local to each invocation.
 */
#include <sys/param.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <resolv.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ios_error.h"

static int
encode(FILE *input, FILE *output, unsigned columns)
{
    unsigned char buf[1023];
    char encoded[sizeof(buf) * 2 + 1];
    size_t n;
    unsigned carry = 0;

    while ((n = fread(buf, 1, sizeof(buf), input)) != 0) {
        int rv = b64_ntop(buf, n, encoded, sizeof(encoded));
        if (rv < 0)
            return 1;
        for (int i = 0; i < rv; ) {
            size_t written = (size_t)(rv - i);
            if (columns && written > columns - carry)
                written = columns - carry;
            if (fwrite(encoded + i, 1, written, output) != written)
                return 1;
            i += (int)written;
            if (columns) {
                carry = (carry + (unsigned)written) % columns;
                if (!carry && fputc('\n', output) == EOF)
                    return 1;
            }
        }
    }
    if (columns == 0 || carry != 0)
        if (fputc('\n', output) == EOF)
            return 1;
    return ferror(input) ? 1 : 0;
}

static int
decode(FILE *input, FILE *output)
{
    char inbuf[MAXPATHLEN + 1], leftover[MAXPATHLEN + 1] = "";
    unsigned char outbuf[MAXPATHLEN * 4];

    for (;;) {
        strcpy(inbuf, leftover);
        size_t len = strlen(inbuf);
        if (fgets(inbuf + len, (int)(sizeof(inbuf) - len), input) == NULL)
            return ferror(input) ? 1 : 0;
        size_t count = 0;
        ptrdiff_t count4 = -1;
        for (char *p = inbuf; *p; p++) {
            unsigned char c = (unsigned char)*p;
            if (isalnum(c) || c == '+' || c == '/' || c == '=' || c == '-' || c == '_')
                count++;
            if (count % 4 == 0)
                count4 = p - inbuf;
        }
        strcpy(leftover, inbuf + count4 + 1);
        inbuf[count4 + 1] = '\0';
        // A partial quartet followed by a full buffer of whitespace must still make progress.
        char *tail = leftover;
        for (char *p = leftover; *p; p++)
            if (!isspace((unsigned char)*p)) *tail++ = *p;
        *tail = '\0';
        if ((size_t)(tail - leftover) == sizeof(leftover) - 1)
            return 1;
        // Apple's codec also accepts base64url; libresolv uses the standard alphabet.
        for (char *p = inbuf; *p; p++) {
            if (*p == '-') *p = '+';
            else if (*p == '_') *p = '/';
        }
        int n = b64_pton(inbuf, outbuf, sizeof(outbuf));
        if (n < 0) {
            // b64decode's optional end marker is accepted by macOS base64 too.
            return strncmp(inbuf, "====", 4) != 0 ||
                strspn(inbuf + 4, " \t\r\n") != strlen(inbuf + 4);
        }
        if (fwrite(outbuf, 1, (size_t)n, output) != (size_t)n)
            return 1;
    }
}

static void
usage(FILE *stream)
{
    fprintf(stream, "Usage: base64 [-Ddeh] [-b num] [-i input] [-o output] [input [output]]\n"
        "  -D, -d, --decode   decode input (default: encode)\n"
        "  -b, --break num    wrap encoded output at num columns (default: 0)\n"
        "  -w, --wrap num     alias for --break\n"
        "  -i, --input file   input file, or - for stdin\n"
        "  -o, --output file  output file, or - for stdout\n"
        "  -e                encode (legacy alias)\n"
        "  -l num            legacy wrap size, rounded down to a multiple of 4 (minimum 4)\n"
        "  -h, -?, --help    display help\n");
}

int
base64_main(int argc, char **argv)
{
    static const struct option options[] = {
        {"decode", no_argument, NULL, 'd'},
        {"break", required_argument, NULL, 'b'},
        {"breaks", required_argument, NULL, 'b'},
        {"wrap", required_argument, NULL, 'b'},
        {"input", required_argument, NULL, 'i'},
        {"output", required_argument, NULL, 'o'},
        {"help", no_argument, NULL, 'h'},
        {NULL, 0, NULL, 0}
    };
    const char *infile = NULL, *outfile = NULL;
    unsigned columns = 0;
    int decoding = 0, ch;
    // Commands can be invoked repeatedly in the same process.
    optind = optreset = 1;
    opterr = 0;
    while ((ch = getopt_long(argc, argv, ":Ddehb:w:l:i:o:?", options, NULL)) != -1) {
        switch (ch) {
        case 'D': case 'd': decoding = 1; break;
        case 'e': decoding = 0; break;
        case 'i': infile = optarg; break;
        case 'o': outfile = optarg; break;
        case 'b': case 'w': case 'l': {
            char *end;
            errno = 0;
            unsigned long value = strtoul(optarg, &end, 10);
            if (*optarg == '\0' || *optarg == '-' || *end || errno || value > UINT_MAX) {
                fprintf(thread_stderr, "base64: invalid wrap size: %s\n", optarg);
                return 1;
            }
            columns = (unsigned)value;
            if (ch == 'l')
                columns = columns < 4 ? 4 : columns / 4 * 4;
            break;
        }
        case 'h': usage(thread_stdout); return 0;
        case '?':
            if (optind > 0 && strcmp(argv[optind - 1], "-?") == 0) {
                usage(thread_stdout);
                return 0;
            }
            /* FALLTHROUGH */
        default: usage(thread_stderr); return 1;
        }
    }
    // Preserve the old b64 input/output operands alongside BSD file options.
    if (optind < argc && infile == NULL) infile = argv[optind++];
    if (optind < argc && outfile == NULL) outfile = argv[optind++];
    if (optind != argc) {
        usage(thread_stderr);
        return 1;
    }
    FILE *input = thread_stdin, *output = thread_stdout;
    if (infile && strcmp(infile, "-") != 0) {
        input = fopen(infile, "rb");
        if (!input) {
            fprintf(thread_stderr, "base64: %s: %s\n", infile, strerror(errno));
            return 1;
        }
    }
    if (outfile && strcmp(outfile, "-") != 0) {
        output = fopen(outfile, "wb");
        if (!output) {
            fprintf(thread_stderr, "base64: %s: %s\n", outfile, strerror(errno));
            if (input != thread_stdin) fclose(input);
            return 1;
        }
    }
    int status = decoding ? decode(input, output) : encode(input, output, columns);
    if (fflush(output) != 0) status = 1;
    if (output != thread_stdout && fclose(output) != 0) status = 1;
    if (input != thread_stdin && fclose(input) != 0) status = 1;
    if (status)
        fprintf(thread_stderr, "base64: %s failed (invalid input or stream error)\n", decoding ? "decoding" : "encoding");
    return status;
}
