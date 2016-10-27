//
//  DaemonState.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonState.h"
#import "Daemon.h"
#import "DaemonState_all.h"

@implementation DaemonState

- (DaemonState *)initWithDaemon:(Daemon *)d
{
    self = [super init];
    if(self)
    {
        daemon = d;
        d.lastRx = [NSDate date];
    }
    return self;
}

- (NSString *)description
{
    return [self name];
}

- (NSString *)name
{
    return @"undefined";
}

- (DaemonState *)eventUnknown:(int)prio randomValue:(long int)r
{
    return  [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventRemoteFailed
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverRequest:(int)prio randomValue:(long int)r
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverConf:(int)prio 
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverReject:(int)prio
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusStandby:(int)prio
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusHot:(int)prio
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTimer
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTimeout
{
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)localFailureIndication
{
    NSLog(@"Unhandled state localFailureIndication in state %@",[self name]);

    [daemon actionSendFailed];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localUnknownIndication /* heartbeat from app */
{
    NSLog(@"Unhandled state localUnknownIndication in state %@",[self name]);
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)localHotIndication /* heartbeat from app */
{
    NSLog(@"Unhandled state localHotIndication in state %@",[self name]);

    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)localStandbyIndication /* heartbeat from app */
{
    NSLog(@"Unhandled state localStandbyIndication in state %@",[self name]);
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (int)takeoverChallenge:(int)prio
             remoteRandom:(DaemonRandomValue)rremote
              localRandom:(DaemonRandomValue)rlocal
{
    if(prio < daemon.localPriority)
    {
        return 1; /* we win */
    }
    else if(prio == daemon.localPriority)
    {
        if(rlocal == rremote)
        {
            return 0;
        }
        if(rlocal > rremote)
        {
            return 1;
        }
        return -1;
    }
    else
    {
        return -1;
    }
}

@end
