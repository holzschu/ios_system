/*********************************************************************\

MODULE NAME:    b64.c

AUTHOR:         Bob Trower 2001/08/04

PROJECT:        Crypt Data Packaging

COPYRIGHT:      Copyright (c) Trantor Standard Systems Inc., 2001

NOTES:          This source code may be used as you wish, subject to
                the MIT license.  See the LICENCE section below.

                Canonical source should be at:
                    http://base64.sourceforge.net

DESCRIPTION:
                This little utility implements the Base64
                Content-Transfer-Encoding standard described in
                RFC1113 (http://www.faqs.org/rfcs/rfc1113.html).

                This is the coding scheme used by MIME to allow
                binary data to be transferred by SMTP mail.

                Groups of 3 bytes from a binary stream are coded as
                groups of 4 bytes in a text stream.

                The input stream is 'padded' with zeros to create
                an input that is an even multiple of 3.

                A special character ('=') is used to denote padding so
                that the stream can be decoded back to its exact size.

                Encoded output is formatted in lines which should
                be a maximum of 72 characters to conform to the
                specification.  This program defaults to 72 characters,
                but will allow more or less through the use of a
                switch.  The program enforces a minimum line size
                of 4 characters.

                Example encoding:

                The stream 'ABCD' is 32 bits long.  It is mapped as
                follows:

                ABCD

                 A (65)     B (66)     C (67)     D (68)   (None) (None)
                01000001   01000010   01000011   01000100

                16 (Q)  20 (U)  9 (J)   3 (D)    17 (R) 0 (A)  NA (=) NA (=)
                010000  010100  001001  000011   010001 000000 000000 000000


                QUJDRA==

                Decoding is the process in reverse.  A 'decode' lookup
                table has been created to avoid string scans.

DESIGN GOALS:	Specifically:
		Code is a stand-alone utility to perform base64 
		encoding/decoding. It should be genuinely useful 
		when the need arises and it meets a need that is 
		likely to occur for some users.  
		Code acts as sample code to show the author's 
		design and coding style.  

		Generally: 
		This program is designed to survive:
		Everything you need is in a single source file.
		It compiles cleanly using a vanilla ANSI C compiler.
		It does its job correctly with a minimum of fuss.  
		The code is not overly clever, not overly simplistic 
		and not overly verbose. 
		Access is 'cut and paste' from a web page.  
		Terms of use are reasonable.  

VALIDATION:     Non-trivial code is never without errors.  This
                file likely has some problems, since it has only
                been tested by the author.  It is expected with most
                source code that there is a period of 'burn-in' when
                problems are identified and corrected.  That being
                said, it is possible to have 'reasonably correct'
                code by following a regime of unit test that covers
                the most likely cases and regression testing prior
                to release.  This has been done with this code and
                it has a good probability of performing as expected.

                Unit Test Cases:

                case 0:empty file:
                    CASE0.DAT  ->  ->
                    (Zero length target file created
                    on both encode and decode.)

                case 1:One input character:
                    CASE1.DAT A -> QQ== -> A

                case 2:Two input characters:
                    CASE2.DAT AB -> QUI= -> AB

                case 3:Three input characters:
                    CASE3.DAT ABC -> QUJD -> ABC

                case 4:Four input characters:
                    case4.dat ABCD -> QUJDRA== -> ABCD

                case 5:All chars from 0 to ff, linesize set to 50:

                    AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIj
                    JCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZH
                    SElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWpr
                    bG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6P
                    kJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKz
                    tLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX
                    2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7
                    /P3+/w==

                case 6:Mime Block from e-mail:
                    (Data same as test case 5)

                case 7: Large files:
                    Tested 28 MB file in/out.

                case 8: Random Binary Integrity:
                    This binary program (b64.exe) was encoded to base64,
                    back to binary and then executed.

                case 9 Stress:
                    All files in a working directory encoded/decoded
                    and compared with file comparison utility to
                    ensure that multiple runs do not cause problems
                    such as exhausting file handles, tmp storage, etc.

                -------------

                Syntax, operation and failure:
                    All options/switches tested.  Performs as
                    expected.

                case 10:
                    No Args -- Shows Usage Screen
                    Return Code 1 (Invalid Syntax)
                case 11:
                    One Arg (invalid) -- Shows Usage Screen
                    Return Code 1 (Invalid Syntax)
                case 12:
                    One Arg Help (-?) -- Shows detailed Usage Screen.
                    Return Code 0 (Success -- help request is valid).
                case 13:
                    One Arg Help (-h) -- Shows detailed Usage Screen.
                    Return Code 0 (Success -- help request is valid).
                case 14:
                    One Arg (valid) -- Uses stdin/stdout (filter)
                    Return Code 0 (Sucess)
                case 15:
                    Two Args (invalid file) -- shows system error.
                    Return Code 2 (File Error)
                case 16:
                    Encode non-existent file -- shows system error.
                    Return Code 2 (File Error)
                case 17:
                    Out of disk space -- shows system error.
                    Return Code 3 (File I/O Error)
                case 18:
                    Too many args -- shows system error.
                    Return Code 1 (Invalid Syntax)

                -------------

                Compile/Regression test:
                    gcc compiled binary under Cygwin
                    Microsoft Visual Studio under Windows 2000
                    Microsoft Version 6.0 C under Windows 2000

DEPENDENCIES:   None

LICENCE:        Copyright (c) 2001 Bob Trower, Trantor Standard Systems Inc.

                Permission is hereby granted, free of charge, to any person
                obtaining a copy of this software and associated
                documentation files (the "Software"), to deal in the
                Software without restriction, including without limitation
                the rights to use, copy, modify, merge, publish, distribute,
                sublicense, and/or sell copies of the Software, and to
                permit persons to whom the Software is furnished to do so,
                subject to the following conditions:

                The above copyright notice and this permission notice shall
                be included in all copies or substantial portions of the
                Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
                KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
                WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
                PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
                OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
                OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
                OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
                SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

VERSION HISTORY:
                Bob Trower 2001/08/04 -- Create Version 0.00.00B
                Bob Trower 2001/08/17 -- Correct documentation, messages.
                                      -- Correct help for linesize syntax.
                                      -- Force error on too many arguments.
                Bob Trower 2001/08/19 -- Add sourceforge.net reference to
                                         help screen prior to release.
                Bob Trower 2004/10/22 -- Cosmetics for package/release.
                Bob Trower 2008/02/28 -- More Cosmetics for package/release.
                Bob Trower 2011/02/14 -- Cast altered to fix warning in VS6.
                Bob Trower 2015/10/29 -- Change *bug* from 0 to EOF in putc
                                         invocation. BIG shout out to people
                                         reviewing on sourceforge, 
                                         particularly rachidc, jorgeventura
                                         and zeroxia. 
                                      -- Change date format to conform with
                                         latest convention.

\******************************************************************* */

#include <stdio.h>
#include <stdlib.h>
#include "ios_error.h"
#define printf(...) fprintf (thread_stdout, ##__VA_ARGS__)
#undef stdout
#define stdout thread_stdout
#undef stdin
#define stdin thread_stdin

/*
** Translation Table as described in RFC1113
*/
static const char cb64[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*
** Translation Table to decode (created by author)
*/
static const char cd64[]="|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq";

/*
** returnable errors
**
** Error codes returned to the operating system.
**
*/
#define B64_SYNTAX_ERROR        1
#define B64_FILE_ERROR          2
#define B64_FILE_IO_ERROR       3
#define B64_ERROR_OUT_CLOSE     4
#define B64_LINE_SIZE_TO_MIN    5
#define B64_SYNTAX_TOOMANYARGS  6

/*
** b64_message
**
** Gather text messages in one place.
**
*/
#define B64_MAX_MESSAGES 7
static char *b64_msgs[ B64_MAX_MESSAGES ] = {
            "b64:000:Invalid Message Code.",
            "b64:001:Syntax Error -- check help (-h) for usage.",
            "b64:002:File Error Opening/Creating Files.",
            "b64:003:File I/O Error -- Note: output file not removed.",
            "b64:004:Error on output file close.",
            "b64:005:linesize set to minimum.",
            "b64:006:Syntax: Too many arguments."
};

#define b64_message( ec ) ((ec > 0 && ec < B64_MAX_MESSAGES ) ? b64_msgs[ ec ] : b64_msgs[ 0 ])

/*
** encodeblock
**
** encode 3 8-bit binary bytes as 4 '6-bit' characters
*/
static void encodeblock( unsigned char *in, unsigned char *out, int len )
{
    out[0] = (unsigned char) cb64[ (int)(in[0] >> 2) ];
    out[1] = (unsigned char) cb64[ (int)(((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4)) ];
    out[2] = (unsigned char) (len > 1 ? cb64[ (int)(((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6)) ] : '=');
    out[3] = (unsigned char) (len > 2 ? cb64[ (int)(in[2] & 0x3f) ] : '=');
}

/*
** encode
**
** base64 encode a stream adding padding and line breaks as per spec.
*/
static int encode( FILE *infile, FILE *outfile, int linesize )
{
    unsigned char in[3];
	unsigned char out[4];
    int i, len, blocksout = 0;
    int retcode = 0;

	*in = (unsigned char) 0;
	*out = (unsigned char) 0;
    while( feof( infile ) == 0 ) {
        len = 0;
        for( i = 0; i < 3; i++ ) {
            in[i] = (unsigned char) getc( infile );

            if( feof( infile ) == 0 ) {
                len++;
            }
            else {
                in[i] = (unsigned char) 0;
            }
        }
        if( len > 0 ) {
            encodeblock( in, out, len );
            for( i = 0; i < 4; i++ ) {
                if( putc( (int)(out[i]), outfile ) == EOF ){
	                if( ferror( outfile ) != 0 )      {
	                    perror( b64_message( B64_FILE_IO_ERROR ) );
	                    retcode = B64_FILE_IO_ERROR;
	                }
					break;
				}
            }
            blocksout++;
        }
        if( blocksout >= (linesize/4) || feof( infile ) != 0 ) {
            if( blocksout > 0 ) {
                fprintf( outfile, "\n" );
            }
            blocksout = 0;
        }
    }
    return( retcode );
}

/*
** decodeblock
**
** decode 4 '6-bit' characters into 3 8-bit binary bytes
*/
static void decodeblock( unsigned char *in, unsigned char *out )
{   
    out[ 0 ] = (unsigned char ) (in[0] << 2 | in[1] >> 4);
    out[ 1 ] = (unsigned char ) (in[1] << 4 | in[2] >> 2);
    out[ 2 ] = (unsigned char ) (((in[2] << 6) & 0xc0) | in[3]);
}

/*
** decode
**
** decode a base64 encoded stream discarding padding, line breaks and noise
*/
static int decode( FILE *infile, FILE *outfile )
{
	int retcode = 0;
    unsigned char in[4];
    unsigned char out[3];
    int v;
    int i, len;

	*in = (unsigned char) 0;
	*out = (unsigned char) 0;
    while( feof( infile ) == 0 ) {
        for( len = 0, i = 0; i < 4 && feof( infile ) == 0; i++ ) {
            v = 0;
            while( feof( infile ) == 0 && v == 0 ) {
                v = getc( infile );
                if( feof( infile ) == 0 ) {
	                v = ((v < 43 || v > 122) ? 0 : (int) cd64[ v - 43 ]);
					if( v != 0 ) {
						v = ((v == (int)'$') ? 0 : v - 61);
					}
                }
            }
            if( feof( infile ) == 0 ) {
                len++;
                if( v != 0 ) {
                    in[ i ] = (unsigned char) (v - 1);
                }
            }
            else {
                in[i] = (unsigned char) 0;
            }
        }
        if( len > 0 ) {
            decodeblock( in, out );
            for( i = 0; i < len - 1; i++ ) {
                if( putc( (int) out[i], outfile ) == EOF ){
	                if( ferror( outfile ) != 0 )      {
	                    perror( b64_message( B64_FILE_IO_ERROR ) );
	                    retcode = B64_FILE_IO_ERROR;
	                }
					break;
				}
            }
        }
    }
    return( retcode );
}

/*
** b64
**
** 'engine' that opens streams and calls encode/decode
*/

static int b64( char opt, char *infilename, char *outfilename, int linesize )
{
    FILE *infile;
    int retcode = B64_FILE_ERROR;

    if( !infilename ) {
        infile = stdin;
    }
    else {
        infile = fopen( infilename, "rb" );
    }
    if( !infile ) {
        perror( infilename );
    }
    else {
        FILE *outfile;
        if( !outfilename ) {
            outfile = stdout;
        }
        else {
            outfile = fopen( outfilename, "wb" );
        }
        if( !outfile ) {
            perror( outfilename );
        }
        else {
            if( opt == 'e' ) {
                retcode = encode( infile, outfile, linesize );
            }
            else {
                retcode = decode( infile, outfile );
            }
			if( retcode == 0 ) {
	            if (ferror( infile ) != 0 || ferror( outfile ) != 0) {
                    perror( b64_message( B64_FILE_IO_ERROR ) );
	                retcode = B64_FILE_IO_ERROR;
	            }
            }
            if( outfile != stdout ) {
                if( fclose( outfile ) != 0 ) {
                    perror( b64_message( B64_ERROR_OUT_CLOSE ) );
                    retcode = B64_FILE_IO_ERROR;
                }
            }
        }
        if( infile != stdin ) {
			if( fclose( infile ) != 0 ) {
				perror( b64_message( B64_ERROR_OUT_CLOSE ) );
				retcode = B64_FILE_IO_ERROR;
			}
        }
    }

    return( retcode );
}

/*
** showuse
**
** display usage information, help, version info
*/
static void showuse( int morehelp )
{
    {
        printf( "\n" );
        printf( "  b64      (Base64 Encode/Decode)    Bob Trower 2001/08/03 \n" );
        printf( "           (C) Copr Bob Trower 1986-2015     Version 0.94R \n" );
        printf( "  Usage:   b64 -option [-l<num>] [<FileIn> [<FileOut>]]\n" );
        printf( "  Purpose: This program is a simple utility that implements\n" );
        printf( "           Base64 Content-Transfer-Encoding (RFC1113).\n" );
    }
    if( morehelp == 0 ) {
        printf( "           Use -h option for additional help.\n" );
    }
    else {
        printf( "  Options: -e  encode to Base64   -h  This help text.\n" );
        printf( "           -d  decode from Base64 -?  This help text.\n" );
        printf( "           -t  Show test instructions. Under Windows the\n" );
        printf( "               following command line will pipe the help\n" );
        printf( "               text to run a test:\n" );
        printf( "                   b64 -t | cmd\n" );
        printf( "  Note:    -l  use to change line size (from 72 characters)\n" );
        printf( "  Returns: 0 = success.  Non-zero is an error code.\n" );
        printf( "  ErrCode: 1 = Bad Syntax, 2 = File Open, 3 = File I/O\n" );
        printf( "  Example: b64 -e binfile b64file     <- Encode to b64\n" );
        printf( "           b64 -d b64file binfile     <- Decode from b64\n" );
        printf( "           b64 -e -l40 infile outfile <- Line Length of 40\n" );
        printf( "  Note:    Will act as a filter, but this should only be\n" );
        printf( "           used on text files due to translations made by\n" );
        printf( "           operating systems.\n" );
        printf( "  Source:  Source code and latest releases can be found at:\n" );
        printf( "           http://base64.sourceforge.net\n" );
        printf( "  Release: 0.94.00, Thu Oct 29 01:36:00 2015, ANSI-SOURCE C\n" );
    }
}

void dotest(void)
{
    printf(":See source code at sourceforge.net for\n");
    printf(":Unit test information.\n");
    printf(":\n");
    printf(":Under Windows the following batch file will\n");
    printf(":do a quick reality check:\n");
    printf("\n");
    printf("@echo off&cls\n");
    printf("copy /b /y b64.exe b64.bin 1>>nul 2>>nul\n");
    printf("b64 -e b64.bin b64.b64\n");
    printf("b64 -d b64.b64 b64.bin.exe\n");
    printf("fc /b b64.exe b64.bin.exe\n");
    printf(":/\\ Should say no differences enountered /\\\n");
    printf("\n");
}

#define B64_DEF_LINE_SIZE   72
#define B64_MIN_LINE_SIZE    4

#define THIS_OPT(ac, av) ((char)(ac > 1 ? av[1][0] == '-' ? av[1][1] : 0 : 0))

/*
** main
**
** parse and validate arguments and call b64 engine or help
*/
int base64_main( int argc, char **argv )
{
    char opt = (char) 0;
    int retcode = 0;
    int linesize = B64_DEF_LINE_SIZE;
    char *infilename = NULL, *outfilename = NULL;

    while( THIS_OPT( argc, argv ) != (char) 0 ) {
        switch( THIS_OPT(argc, argv) ) {
            case 'l':
                    linesize = atoi( &(argv[1][2]) );
                    if( linesize < B64_MIN_LINE_SIZE ) {
                        linesize = B64_MIN_LINE_SIZE;
                        printf( "%s\n", b64_message( B64_LINE_SIZE_TO_MIN ) );
                    }
                    break;
            case '?':
            case 'h':
                    opt = 'h';
                    break;
            case 'e':
            case 'd':
                    opt = THIS_OPT(argc, argv);
                    break;
            case 't':
                    opt = THIS_OPT(argc, argv);
                    break;
             default:
                    opt = (char) 0;
                    break;
        }
        argv++;
        argc--;
    }
    if( argc > 3 ) {
        printf( "%s\n", b64_message( B64_SYNTAX_TOOMANYARGS ) );
        opt = (char) 0;
    }
    switch( opt ) {
        case 'e':
        case 'd':
            infilename = argc > 1 ? argv[1] : NULL;
            outfilename = argc > 2 ? argv[2] : NULL;
            retcode = b64( opt, infilename, outfilename, linesize );
            break;
        case 0:
			if( argv[1] == NULL ) {
				showuse( 0 );
			}
			else {
				retcode = B64_SYNTAX_ERROR;
			}
			break;
        case 'h':
            showuse( (int) opt );
            break;
        case 't':
            dotest();
            break;

    }
    if( retcode != 0 ) {
        printf( "%s\n", b64_message( retcode ) );
    }

    return( retcode );
}
