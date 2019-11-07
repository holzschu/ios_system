//
//  sessionParameters.m
//  ios_system
//
//  Created by Nicolas Holzschuch on 23/03/2018.
//  Copyright © 2018 Nicolas Holzschuch. All rights reserved.
//

#import "sessionParameters.h"

@implementation sessionParameters

- (instancetype)init
{
    self = [super init];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    self.isMainThread = TRUE;
    self.current_command_root_thread = 0;
    self.lastThreadId = 0;
    self.currentDir = [fileManager currentDirectoryPath];
    self.previousDirectory = [fileManager currentDirectoryPath];
    self.localMiniRoot = nil;
    self.global_errno = 0;
    self.stdin = stdin;
    self.stdout = stdout;
    self.stderr = stderr;
    self.context = nil; 
    self.commandName = nil;
    self.columns = @"80";
    self.lines = @"80";
  
    return self;
}

@end
