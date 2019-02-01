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
  return @[@"googlechrome", @"firefox", @"safari"];
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
  
  if ([browser isEqualToString:@"firefox"]) {
    NSString *url = [absSrcURLStr
                        stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    url = [@"firefox://open-url?url=" stringByAppendingString:url];
    return [NSURL URLWithString:url];
  }
  
  if ([browser isEqualToString:@"yandexbrowser"]) {
    NSString *url = [absSrcURLStr
                     stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    url = [@"yandexbrowser-open-url://" stringByAppendingString:url];
    return [NSURL URLWithString:url];
  }
  
  NSString *browserAppUrlStr = [absSrcURLStr stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:browser];
  return [NSURL URLWithString:browserAppUrlStr];
}

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
