/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     FIRSTTOKEN = 258,
     PROGRAM = 259,
     PASTAT = 260,
     PASTAT2 = 261,
     XBEGIN = 262,
     XEND = 263,
     NL = 264,
     ARRAY = 265,
     MATCH = 266,
     NOTMATCH = 267,
     MATCHOP = 268,
     FINAL = 269,
     DOT = 270,
     ALL = 271,
     CCL = 272,
     NCCL = 273,
     CHAR = 274,
     HAT = 275,
     DOLLAR = 276,
     OR = 277,
     STAR = 278,
     QUEST = 279,
     PLUS = 280,
     EMPTYRE = 281,
     ZERO = 282,
     IGNORE_PRIOR_ATOM = 283,
     AND = 284,
     BOR = 285,
     APPEND = 286,
     EQ = 287,
     GE = 288,
     GT = 289,
     LE = 290,
     LT = 291,
     NE = 292,
     IN = 293,
     ARG = 294,
     BLTIN = 295,
     BREAK = 296,
     CLOSE = 297,
     CONTINUE = 298,
     DELETE = 299,
     DO = 300,
     EXIT = 301,
     FOR = 302,
     FUNC = 303,
     SUB = 304,
     GSUB = 305,
     IF = 306,
     INDEX = 307,
     LSUBSTR = 308,
     MATCHFCN = 309,
     NEXT = 310,
     NEXTFILE = 311,
     ADD = 312,
     MINUS = 313,
     MULT = 314,
     DIVIDE = 315,
     MOD = 316,
     ASSIGN = 317,
     ASGNOP = 318,
     ADDEQ = 319,
     SUBEQ = 320,
     MULTEQ = 321,
     DIVEQ = 322,
     MODEQ = 323,
     POWEQ = 324,
     PRINT = 325,
     PRINTF = 326,
     SPRINTF = 327,
     ELSE = 328,
     INTEST = 329,
     CONDEXPR = 330,
     POSTINCR = 331,
     PREINCR = 332,
     POSTDECR = 333,
     PREDECR = 334,
     VAR = 335,
     IVAR = 336,
     VARNF = 337,
     CALL = 338,
     NUMBER = 339,
     STRING = 340,
     REGEXPR = 341,
     GETLINE = 342,
     SUBSTR = 343,
     SPLIT = 344,
     RETURN = 345,
     WHILE = 346,
     CAT = 347,
     UPLUS = 348,
     UMINUS = 349,
     NOT = 350,
     POWER = 351,
     INCR = 352,
     DECR = 353,
     INDIRECT = 354,
     LASTTOKEN = 355
   };
#endif
/* Tokens.  */
#define FIRSTTOKEN 258
#define PROGRAM 259
#define PASTAT 260
#define PASTAT2 261
#define XBEGIN 262
#define XEND 263
#define NL 264
#define ARRAY 265
#define MATCH 266
#define NOTMATCH 267
#define MATCHOP 268
#define FINAL 269
#define DOT 270
#define ALL 271
#define CCL 272
#define NCCL 273
#define CHAR 274
#define HAT 275
#define DOLLAR 276
#define OR 277
#define STAR 278
#define QUEST 279
#define PLUS 280
#define EMPTYRE 281
#define ZERO 282
#define IGNORE_PRIOR_ATOM 283
#define AND 284
#define BOR 285
#define APPEND 286
#define EQ 287
#define GE 288
#define GT 289
#define LE 290
#define LT 291
#define NE 292
#define IN 293
#define ARG 294
#define BLTIN 295
#define BREAK 296
#define CLOSE 297
#define CONTINUE 298
#define DELETE 299
#define DO 300
#define EXIT 301
#define FOR 302
#define FUNC 303
#define SUB 304
#define GSUB 305
#define IF 306
#define INDEX 307
#define LSUBSTR 308
#define MATCHFCN 309
#define NEXT 310
#define NEXTFILE 311
#define ADD 312
#define MINUS 313
#define MULT 314
#define DIVIDE 315
#define MOD 316
#define ASSIGN 317
#define ASGNOP 318
#define ADDEQ 319
#define SUBEQ 320
#define MULTEQ 321
#define DIVEQ 322
#define MODEQ 323
#define POWEQ 324
#define PRINT 325
#define PRINTF 326
#define SPRINTF 327
#define ELSE 328
#define INTEST 329
#define CONDEXPR 330
#define POSTINCR 331
#define PREINCR 332
#define POSTDECR 333
#define PREDECR 334
#define VAR 335
#define IVAR 336
#define VARNF 337
#define CALL 338
#define NUMBER 339
#define STRING 340
#define REGEXPR 341
#define GETLINE 342
#define SUBSTR 343
#define SPLIT 344
#define RETURN 345
#define WHILE 346
#define CAT 347
#define UPLUS 348
#define UMINUS 349
#define NOT 350
#define POWER 351
#define INCR 352
#define DECR 353
#define INDIRECT 354
#define LASTTOKEN 355




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 41 "awkgram.y"
{
	Node	*p;
	Cell	*cp;
	int	i;
	char	*s;
}
/* Line 1529 of yacc.c.  */
#line 256 "awkgram.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern __thread YYSTYPE yylval;

