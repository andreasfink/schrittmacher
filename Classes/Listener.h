//
//  Listener.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
@class Daemon;

@interface Listener : UMObject
{
    UMHost *            _localHostPublic;
    UMHost *            _localHostPrivate;
    int                 _publicPort;
    int                 _privatePort;
    NSMutableDictionary *_daemons;
    UMSocket            *_ucPublic;
    UMSocket            *_ucPrivate;
    int                 _addressType;
}

@property(readwrite,strong) UMHost *localHostPublic;
@property(readwrite,strong) UMHost *localHostPrivate;
@property(readwrite,assign) int publicPort;
@property(readwrite,assign) int privatePort;
@property(readwrite,assign) int addressType;


- (void)start;
- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p;
- (void) attachDaemon:(Daemon *)d;
- (void)checkForPackets;
- (void)checkForTimeouts;
- (void)heartbeat;
- (NSDictionary *)status;
- (void)failover:(NSString *)name;
- (void)takeover:(NSString *)name;
- (void)checkIfUp;
- (void)receiveStatus:(NSData *)statusData fromAddress:(NSString *)address;

@end
