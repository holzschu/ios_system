From pauzner.dnttm.rssi.ru!uue@pauzner.dnttm.rssi.ru  Wed Jan 14 05:40:34 1998
Received: from allison.clark.net (allison.clark.net [207.97.14.170])
	by ice.clark.net (8.8.8/8.8.8) with ESMTP id FAA28956
	for <dickey@shell.clark.net>; Wed, 14 Jan 1998 05:40:28 -0500 (EST)
Received: from helios.dnttm.ru (dnttm.wave.ras.ru [194.85.104.197])
	by allison.clark.net (8.8.8/8.8.8) with ESMTP id NAA05915
	for <dickey@clark.net>; Mon, 12 Jan 1998 13:50:43 -0500 (EST)
Received: from pauzner.UUCP (uucp@localhost)
	by helios.dnttm.ru (8.8.5/8.8.5/IP-3) with UUCP id VAA21992
	for dickey@clark.net; Mon, 12 Jan 1998 21:46:03 +0300
Received: by pauzner.dnttm.rssi.ru (dMail for DOS v2.06, 14Jul97);
          Mon, 12 Jan 1998 21:44:21 +0300
To: dickey@shell.clark.net
References: <AAyibkq8tH@pauzner.dnttm.rssi.ru>
Message-Id: <AB3Ickqyu0@pauzner.dnttm.rssi.ru>
From: "Leonid Pauzner" <uue@pauzner.dnttm.rssi.ru>
Date: Mon, 12 Jan 1998 21:44:19 +0300 (MSK)
X-Mailer: dMail [Demos Mail for DOS v2.06]
Subject: Re: please submit a patch NOW
Lines: 276
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Status: RO

This is for russian Cyrillic chartrans only:
koi8-r and other Cyrillics now fall down to def7_uni transliteration
if necessary (as should be). No "strip high bit" any more for koi8-r
(UCAux.c), which made text completely unreadable for human
and come from "before Unicode Era".
(Somebody should look in LYCharUtil.c and LYCharSet.c
to remove unnecessary staff where)

Leonid Pauzner.



*** UCAux.c     Thu Jan  8 16:53:06 1998
--- UCAux.c.new   Sat Jan 10 15:40:48 1998
***************
*** 64,70 ****
            /*
            **  CJK mode may be off (i.e., HTCJK == NOCJK) because
            **  the current document is not CJK, but the check may
!           **  be for capability in relation to another document,
            **  for which CJK mode might be turned on when retrieved.
            **  Thus, when the from charset is CJK, check if the to
            **  charset is CJK, and return TQ_NO or TQ_GOOD depending on
--- 64,70 ----
            /*
            **  CJK mode may be off (i.e., HTCJK == NOCJK) because
            **  the current document is not CJK, but the check may
!           **  be for campability in relation to another document,
            **  for which CJK mode might be turned on when retrieved.
            **  Thus, when the from charset is CJK, check if the to
            **  charset is CJK, and return TQ_NO or TQ_GOOD depending on
***************
*** 84,113 ****
            **/
            return TQ_NO;
        }
!       if (!strcmp(fromname, "koi8-r")) {
!           /*
!            *  Will try to use stripping of high bit...
!            */
!           tqmin = TQ_POOR;
!       }
!
!       if (!strcmp(fromname, "koi8-r") || /* from cyrillic */
!           !strcmp(fromname, "iso-8859-5") ||
!           !strcmp(fromname, "cp866") ||
!           !strcmp(fromname, "cp1251") ||
!           !strcmp(fromname, "koi-8")) {
!           if (strcmp(toname, "iso-8859-5") &&
!               strcmp(toname, "koi8-r") &&
!               strcmp(toname, "cp866") &&
!               strcmp(toname, "cp1251"))
!               tqmax = TQ_POOR;
!       }
        return ((LYCharSet_UC[from].UChndl >= 0) ? tqmax : tqmin);
      }
  }

  /*
! **  Returns YES if no tranlation necessary (because
  **  charsets are equal, are equivalent, etc.).
  */
  PUBLIC BOOL UCNeedNotTranslate ARGS2(
--- 84,98 ----
            **/
            return TQ_NO;
        }
!       /*  I am not sure with tqmax and tqmin :
!       **  does we need them in this procedure et all now?  -LP
!       */
        return ((LYCharSet_UC[from].UChndl >= 0) ? tqmax : tqmin);
      }
  }

  /*
! **  Returns YES if no translation necessary (because
  **  charsets are equal, are equivalent, etc.).
  */
  PUBLIC BOOL UCNeedNotTranslate ARGS2(
***************
*** 274,296 ****
            **  We set this, presently, for VISCII. - FM
            */
            pT->repl_translated_C0 = (p_out->enc == UCT_ENC_8BIT_C0);
-           /*
-           **  This is a flag for whether we are dealing with koi8-r
-           **  as the input, and could do 8th-bit stripping for other
-           **  output charsets.  Note that this always sets 8th-bit
-           **  stripping if the input charset is KOI8-R and the output
-           **  charset needs it, i.e., regardless of the RawMode and
-           **  consequent HTPassEightBitRaw setting, so you can't look
-           **  at raw koi8-r without selecting that as the display
-           **  character set (or transparent).  That's just as well,
-           **  but worth noting for developers - FM
-           */
-           pT->strip_raw_char_in = ((!intm_ucs ||
-                                     (p_out->enc == UCT_ENC_7BIT) ||
-                                     (p_out->repertoire &
-                                      UCT_REP_SUBSETOF_LAT1)) &&
-                                    cs_in != cs_out &&
-                                    !strcmp(p_in->MIMEname, "koi8-r"));
            /*
            **  use_ucs should be set TRUE if we have or will create
            **  Unicode values for input octets or UTF multibytes. - FM
--- 259,264 ----

*** def7_uni.tbl        Sun Nov 16 20:36:50 1997
--- def7_uni.tbl.new        Sat Jan 10 15:14:34 1998
***************
*** 232,237 ****
--- 232,238 ----
  # IPA symbols, from
  #   Linkname: FAQ: Representing IPA Phonetics in ASCII
  #        URL: http://www.hpl.hp.com/personal/Evan_Kirshenbaum/IPA/faq.html
+ #        (corrected in Russian Cyrillic area).
  #
  0x41  U+0251 #        LATIN SMALL LETTER SCRIPT A     -> A
  U+0252:A.
***************
*** 418,424 ****
  U+03f4:'%
  U+03f5:j3
  # Cyrillic capital letters
- 0x65  U+0401
  U+0402:D%
  U+0403:G%
  U+0404:IE
--- 419,424 ----
***************
*** 432,481 ****
  U+040c:KJ
  U+040e:V%
  U+040f:DZ
! 0x61-0x62     U+0410-U+0411
! 0x77  U+0412
! 0x67  U+0413
! 0x64-0x65     U+0414-U+0415
! 0x76  U+0416
! 0x7a  U+0417
! 0x69-0x70     U+0418-U+041f
! 0x72-0x75     U+0420-U+0423
! 0x66  U+0424
! 0x68  U+0425
! 0x63  U+0426
! 0x7e  U+0427
! 0x7b  U+0428
! 0x7d  U+0429
! 0x27  U+042a
! 0x79  U+042b
! 0x78  U+042c
! 0x7c  U+042d
! 0x60  U+042e
! 0x71  U+042f
!
! # Cyrillic small letters
! 0x41-0x42     U+0430-U+0431
! 0x57  U+0432
! 0x47  U+0433
! 0x44-0x45     U+0434-U+0435
! 0x56  U+0436
! 0x5a  U+0437
! 0x49-0x50     U+0438-U+043f
! 0x52-0x55     U+0440-U+0443
! 0x46  U+0444
! 0x48  U+0445
! 0x43  U+0446
! 0x5e  U+0447
! 0x5b  U+0448
! 0x5d  U+0449
! 0x27  U+044a
! 0x59  U+044b
! 0x58  U+044c
! 0x5c  U+044d
! 0x40  U+044e
! 0x51  U+044f
!
! 0x65  U+0451  #:io
  U+0452:d%
  U+0453:g%
  U+0454:ie
--- 432,506 ----
  U+040c:KJ
  U+040e:V%
  U+040f:DZ
! # Russian Cyrillic letters, transliterated
! U+0401:IO
! U+0410:A
! U+0411:B
! U+0412:V
! U+0413:G
! U+0414:D
! U+0415:E
! U+0416:ZH
! U+0417:Z
! U+0418:I
! U+0419:J
! U+041a:K
! U+041b:L
! U+041c:M
! U+041d:N
! U+041e:O
! U+041f:P
! U+0420:R
! U+0421:S
! U+0422:T
! U+0423:U
! U+0424:F
! U+0425:H
! U+0426:C
! U+0427:CH
! U+0428:SH
! U+0429:SCH
! U+042a:"
! U+042b:Y
! U+042c:'
! U+042d:`E
! U+042e:JU
! U+042f:JA
! U+0430:a
! U+0431:b
! U+0432:v
! U+0433:g
! U+0434:d
! U+0435:e
! U+0436:zh
! U+0437:z
! U+0438:i
! U+0439:j
! U+043a:k
! U+043b:l
! U+043c:m
! U+043d:n
! U+043e:o
! U+043f:p
! U+0440:r
! U+0441:s
! U+0442:t
! U+0443:u
! U+0444:f
! U+0445:h
! U+0446:c
! U+0447:ch
! U+0448:sh
! U+0449:sch
! U+044a:"
! U+044b:y
! U+044c:'
! U+044d:`e
! U+044e:ju
! U+044f:ja
! U+0451:io
! # end of Russian Cyrillic letters.
! # Cyrillic small letters (and some archaic)
  U+0452:d%
  U+0453:g%
  U+0454:ie
***************
*** 1432,1438 ****
  U+223e:CG
  U+2243:?-
  U+2245:?=
! U+2248:?2
  U+224c:=?
  U+2253:HI
  U+2260:!=
--- 1457,1464 ----
  U+223e:CG
  U+2243:?-
  U+2245:?=
! # ALMOST EQUAL TO:
! U+2248:~=
  U+224c:=?
  U+2253:HI
  U+2260:!=




