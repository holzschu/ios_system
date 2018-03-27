/* $OpenBSD: readpass.c,v 1.51 2015/12/11 00:20:04 mmcc Exp $ */
/*
 * Copyright (c) 2001 Markus Friedl.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "includes.h"
#include "xmalloc.h"
/* #include "misc.h"
#include "pathnames.h"
#include "log.h"
#include "ssh.h"
#include "uidswap.h" */
#include "ios_error.h"
#import <UIKit/UIKit.h>

static char* ret;
static bool done = false;

static void setPassword(const char* password) {
    ret = xstrdup(password);
    done = true;
}

/*
 * Reads a passphrase using an iOS alert with secureTextEntry
 * Only way to prevent password to be in the terminal.
 */
char *
read_passphrase(const char *prompt, int flags)
{
    // Need to get the root controller without having access to "self".
    UIViewController *topViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    if (!topViewController) return xstrdup("");
    while (topViewController.presentedViewController) topViewController = topViewController.presentedViewController;
    // alerts have to go to the main queue:
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithUTF8String:prompt]
            message:nil
            preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
         textField.placeholder = @"passphrase";
         textField.textColor = [UIColor blueColor];
         textField.clearButtonMode = UITextFieldViewModeWhileEditing;
         textField.borderStyle = UITextBorderStyleRoundedRect;
         textField.secureTextEntry = YES;
         }];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                    NSArray * textfields = alertController.textFields;
                                    UITextField * passwordfiled = textfields[0];
                                    setPassword([passwordfiled.text UTF8String]);
                                    // TODO: explicit_bzero of passwordfiled -- impossible?
                                    }]];
        [topViewController presentViewController:alertController animated:YES completion:nil];
    });
    while (!done) {};
    done = false;
    return ret;
}


void systemAlert(char* prompt) {
    // Need to get the root controller without having access to "self".
    UIViewController *topViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topViewController.presentedViewController) topViewController = topViewController.presentedViewController;
    // alerts have to go to the main queue:
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertController* alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithUTF8String:prompt]
            message:nil
            preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                    done = true;
                                    }]];
        [topViewController presentViewController:alertController animated:YES completion:nil];
    });
    while (!done) {};
    done = false;
}
