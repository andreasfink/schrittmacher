//
//  DaemonState.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>

#import "DaemonRandomValue.h"

@class Daemon;

@interface DaemonState: UMObject
{
    Daemon *daemon;
}
- (NSString *)name;

- (DaemonState *)initWithDaemon:(Daemon *)d;

#pragma mark - Remote Status
- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict;

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu;
- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict;
- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict;
- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict;

#pragma mark - Remote Commands
- (DaemonState *)eventTakeoverRequest:(NSDictionary *)dict;
- (DaemonState *)eventTakeoverConf:(NSDictionary *)dict;
- (DaemonState *)eventTakeoverReject:(NSDictionary *)dict;

#pragma mark - Timer Events
- (DaemonState *)eventToStandbyTimer;
- (DaemonState *)eventToHotTimer;
- (DaemonState *)eventTimer;
- (DaemonState *)eventTimeout;

#pragma mark - Helper
- (int)takeoverChallenge:(NSDictionary *)dict;

/* returns 1 if we win, -1 if the other wins and 0 if we have a tie */


@end
