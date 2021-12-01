//
//  Listener.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
@class Daemon;

@interface Listener : UMBackgrounder
{
    NSString             *_localAddress;
    NSString             *_peerAddress;
    int                 _localPort;
    int                 _remotePort;
    UMLogHandler        *_logHandler;
    UMSynchronizedDictionary *_daemons;
    UMSocket            *_rxSocket;
    int                 _addressType;
    //UMTimer             *_pollTimer;
    UMLogLevel          _logLevel;
    NSString            *_lastError;
}

@property(readwrite,strong) NSString *localAddress;
@property(readwrite,strong) NSString *peerAddress;
@property(readwrite,assign) int localPort;
@property(readwrite,assign) int remotePort;
@property(readwrite,assign) int addressType;
@property(readwrite,assign) UMLogLevel logLevel;
@property(readwrite,strong) UMLogHandler *logHandler;
@property(readwrite,strong) NSString *lastError;

- (void)start;
- (int)checkForPackets;
- (NSDictionary *)status;
- (void)failover:(NSString *)name;
- (void)takeover:(NSString *)name;
- (void)receiveStatus:(NSData *)statusData fromAddress:(NSString *)address;
@end
