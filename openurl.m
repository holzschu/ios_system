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


int openurl_main(int argc, char *argv[]) {
    optind = 1;
    
    
    NSString *usage = @"Usage: openurl url";
    
    if (argc < 2) {
        printf("%s\n", usage.UTF8String);
        return -1;
    }
    
    NSURL *locationURL = [NSURL URLWithString:@(argv[1])];
    
    [[UIApplication sharedApplication] openURL:locationURL options:@{} completionHandler:nil];
    
    return 0;
}
