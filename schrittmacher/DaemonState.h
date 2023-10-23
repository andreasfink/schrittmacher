//
//  DaemonState.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>

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
- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict;
- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict;

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu;
- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict;
- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict;
- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict;
- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict;
- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict;

#pragma mark - GUI commands
- (DaemonState *)eventForceFailover:(NSDictionary *)dict;
- (DaemonState *)eventForceTakeover:(NSDictionary *)dict;


#pragma mark - Timer Events
- (DaemonState *)eventHeartbeat;   /* called to state machine on regular intervalls */
- (DaemonState *)eventRemoteTimeout; /* called when no messages are received from remote daemon */
- (DaemonState *)eventLocalTimeout; /* called when no messages are received from local app */

#pragma mark - Helper
- (int)takeoverChallenge:(NSDictionary *)dict;
- (void)logEvent:(NSString *)event;

/* returns 1 if we win, -1 if the other wins and 0 if we have a tie */


@end
