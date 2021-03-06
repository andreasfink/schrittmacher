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
    NSString            *_localAddress;
    int                 _port;
    UMLogHandler        *_logHandler;
    NSMutableDictionary *_daemons;
    UMSocket            *_rxSocket;
    UMSocket            *_txSocket;
    int                 _addressType;
    UMTimer             *_pollTimer;
    UMLogLevel          _logLevel;
}

@property(readwrite,strong) NSString *localAddress;
@property(readwrite,assign) int port;
@property(readwrite,assign) int addressType;
@property(readwrite,strong) UMTimer *pollTimer;
@property(readwrite,assign) UMLogLevel logLevel;
@property(readwrite,strong) UMLogHandler *logHandler;

- (void)start;
- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p;
- (void) attachDaemon:(Daemon *)d;
- (int)checkForPackets;
- (NSDictionary *)status;
- (void)failover:(NSString *)name;
- (void)takeover:(NSString *)name;
- (void)receiveStatus:(NSData *)statusData fromAddress:(NSString *)address;
@end
