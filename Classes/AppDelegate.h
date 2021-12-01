//
//  AppDelegate.h
//  schrittmacher
//
//  Created by Andreas Fink on 20/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
@class ListenerPeer;
@class ListenerLocal;

@interface AppDelegate : UMObject<UMHTTPServerHttpGetPostDelegate>
{
    UMConfig            *_config;
    time_t              _g_startup_time;
    
    UMTaskQueue         *_mainTaskQueue;
    UMLogConsole        *_console;
    UMLogHandler        *_mainLogHandler;
    UMHTTPServer        *_httpServer;
    
    int                 _localPort;
    int                 _peerPort;
    int                 _webPort;
    NSString            *_logDirectory;
    NSTimeInterval      _heartbeat;
    NSTimeInterval      _timeout;
    
    NSString            *_localAddress4;
    NSString            *_localAddress6;
    NSString            *_remoteAddress;
    NSString            *_sharedAddress;
    ListenerLocal      *_listenerLocal;
    ListenerPeer       *_listenerPeer;
    UMLogLevel          _logLevel;
    UMPrometheus        *_prometheus;
    UMSynchronizedArray *_daemons;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@property(readwrite,strong,atomic)  UMConfig *config;
@property(readonly,assign)          time_t g_statup_time;
@property(readwrite,assign)         UMLogLevel logLevel;

@end
