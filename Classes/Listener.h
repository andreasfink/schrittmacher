//
//  Listener.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <ulib/ulib.h>
@class Daemon;

@interface Listener : UMObject
{
    UMHost *localHost;
    int port;
    NSMutableDictionary *daemons;
    UMSocket *uc;
    int addressType;
}

@property(readwrite,strong) UMHost *localHost;
@property(readwrite,assign) int port;
@property(readwrite,assign) int addressType;


- (void)start;
- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p;
- (void) attachDaemon:(Daemon *)d;
- (void)checkForPackets;
- (void)checkForTimeouts;
- (void)heartbeat;
- (NSDictionary *)status;
- (void)failover:(NSString *)name;
- (void)checkIfUp;
- (void)receiveStatus:(NSData *)statusData fromAddress:(NSString *)address;

@end
