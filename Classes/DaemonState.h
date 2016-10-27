//
//  DaemonState.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
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
- (DaemonState *)eventUnknown:(int)prio randomValue:(long int)r;
- (DaemonState *)eventRemoteFailed;
- (DaemonState *)eventTakeoverRequest:(int)prio randomValue:(long int)r;
- (DaemonState *)eventTakeoverConf:(int)prio;
- (DaemonState *)eventTakeoverReject:(int)prio;
- (DaemonState *)eventStatusStandby:(int)prio;
- (DaemonState *)eventStatusHot:(int)prio;
- (DaemonState *)localFailureIndication;

- (DaemonState *)localUnknownIndication;
- (DaemonState *)localHotIndication;
- (DaemonState *)localStandbyIndication;

- (DaemonState *)eventTimer;
- (DaemonState *)eventTimeout;

- (int)takeoverChallenge:(int)prio
            remoteRandom:(DaemonRandomValue)rremote
             localRandom:(DaemonRandomValue)rlocal;
/* returns 1 if we win, -1 if the other wins and 0 if we have a tie */


@end
