//
//  openurl.m
//  ios_system
//
//  Created by Nicolas Holzschuch on 11/01/2019.
//  Copyright © 2019 Nicolas Holzschuch. All rights reserved.
//
#include <stdio.h>
#include "ios_system/ios_system.h"
#include "ios_error.h"
#import <Foundation/Foundation.h>


NSArray<NSString *> *__known_browsers() {
  // TODO: @"opera" opera-http(s): doesn't work
  return @[@"googlechrome", @"firefox", @"safari", @"yandexbrowser", @"brave", @"opera"];
}

NSURL *__browser_app_url(NSURL *srcURL) {
  if (!srcURL) {
    return nil;
  }
  
  NSString *scheme = srcURL.scheme;
  BOOL isWebLink = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
  if (!isWebLink) {
    return nil;
  }
  
  char *browserEnvVar = getenv("BROWSER");
  if (!browserEnvVar) {
    return nil;
  }

  NSString *browser = [@(browserEnvVar) lowercaseString];
  if (![__known_browsers() containsObject:browser]) {
    return nil;
  }
  
  if ([browser isEqualToString:@"safari"]) {
    return nil;
  }
  
  NSString *absSrcURLStr = [srcURL absoluteString];
  
  // browsers with the open-url scheme:
  if (([browser isEqualToString:@"firefox"]) ||
      ([browser isEqualToString:@"brave"]) ||
      ([browser isEqualToString:@"opera"])) {
    NSString *url = [absSrcURLStr
                        stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSString *openUrl = [@"://open-url?url=" stringByAppendingString:url];
    url = [browser stringByAppendingString:openUrl];
    return [NSURL URLWithString:url];
  }
  
  if ([browser isEqualToString:@"yandexbrowser"]) {
    NSString *url = [absSrcURLStr
                     stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    url = [@"yandexbrowser-open-url://" stringByAppendingString:url];
    return [NSURL URLWithString:url];
  }
  
  // googlechrome: replace "http" with "googlechrome"
  NSString *browserAppUrlStr = [absSrcURLStr stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:browser];
  return [NSURL URLWithString:browserAppUrlStr];
}

// ------------------------------------------------------------------------------------------------
// The `openurl` command still available. The `open` command checks if the passed argument is a file path, if it is, it opens it with an `UIActivityViewController` and if not, it calls the `openurl` command.
// ------------------------------------------------------------------------------------------------

// MARK: - URL

int openurl_main(int argc, char *argv[]) {
  
  NSString *usage = [@[@"Usage: openurl url",
                       @"you can change default browser with BROWSER env var:",
                       [NSString stringWithFormat: @"  %@", [__known_browsers() componentsJoinedByString:@", "]],
                       ] componentsJoinedByString:@"\n"];
  
  if (argc < 2) {
    printf("%s\n", usage.UTF8String);
    return -1;
  }
  
  NSURL *locationURL = [NSURL URLWithString:@(argv[1])];
  if (!locationURL) {
    printf("%s\n", "Invalid URL");
    return -1;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    NSURL *browserAppURL = __browser_app_url(locationURL);
    [[UIApplication sharedApplication] openURL:browserAppURL ?: locationURL
                                       options:@{}
                             completionHandler:nil];
  });
  
  
  return 0;
}

// MARK: - File path

int open_main(int argc, char *argv[]) {
  NSString *usage = [@[@"Usage: open url|path",
                       @"you can change default browser with BROWSER env var:",
                       [NSString stringWithFormat: @"  %@", [__known_browsers() componentsJoinedByString:@", "]],
                       ] componentsJoinedByString:@"\n"];
  
  if (argc < 2) {
    printf("%s\n", usage.UTF8String);
    return -1;
  }
  
  NSURL *fileURL = [NSURL fileURLWithPath:[@(argv[1]) stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] relativeToURL:[NSURL fileURLWithPath:NSFileManager.defaultManager.currentDirectoryPath]];
  
  if (fileURL && [NSFileManager.defaultManager fileExistsAtPath:fileURL.path]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      UIWindow *window = [UIApplication sharedApplication].keyWindow;
      
      if (!window) {
        fputs("Cannot find a window. This command require an UI for opening files.\n", thread_stderr);
      }
      
      UIViewController *topController = window.rootViewController;
      
      while (topController.presentedViewController) {
        topController = topController.presentedViewController;
      }
      
      if (topController == NULL) {
        fputs("Cannot find a View controller on the app window. This command require an UI for opening files.\n", thread_stderr);
      }
      
      UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:NULL];
      activityViewController.excludedActivityTypes = @[@"com.apple.mobilenotes.SharingExtension"]; // Notes fails every time (and blocks the app).
      activityViewController.popoverPresentationController.sourceView = window;
      activityViewController.popoverPresentationController.sourceRect = CGRectZero;
      [topController presentViewController:activityViewController animated:YES completion:NULL];
    });
    return 0;
  }
  
  return openurl_main(argc, argv);
}
