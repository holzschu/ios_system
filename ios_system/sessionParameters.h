//
//  sessionParameters.h
//  ios_system
//
//  Created by Nicolas Holzschuch on 23/03/2018.
//  Copyright © 2018 Nicolas Holzschuch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface sessionParameters : NSObject

@property bool isMainThread;   // are we on the first command?
@property NSString *currentDir;
@property NSString *previousDirectory;
@property NSURL    *localMiniRoot;
@property pthread_t current_command_root_thread; // thread ID of first command
@property pthread_t lastThreadId; // thread ID of last command
@property FILE* stdin;
@property FILE* stdout;
@property FILE* stderr;
@property void* context;
@property int global_errno;
@property NSString* commandName;
@property NSString* columns;
@property NSString* lines;

- (instancetype)init;

@end
