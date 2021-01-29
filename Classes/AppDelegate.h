//
//  AppDelegate.h
//  schrittmacher
//
//  Created by Andreas Fink on 20/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
@class Listener;

@interface AppDelegate : UMObject<UMHTTPServerHttpGetPostDelegate>
{
    UMConfig            *config;
    time_t              g_startup_time;
    
    UMTaskQueue         *mainTaskQueue;
    UMLogConsole        *console;
    UMLogHandler        *mainLogHandler;
    UMHTTPServer        *httpServer;
    
    int                 _publicPort;
    int                 _privatePort;
    int                 webPort;
    NSString            *logDirectory;
    NSTimeInterval      heartbeat;
    NSTimeInterval      timeout;
    
    NSString            *localAddress;
    NSString            *remoteAddress;
    NSString            *sharedAddress;
    NSTimer             *updateTimer;
    NSTimer             *pollTimer;
    NSTimer             *checkIfUpTimer;
    Listener            *listener;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@property(strong)   UMConfig *config;
@property(readonly) time_t g_statup_time;

@end
