//
//  DaemonState_Standby.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonState_all.h"

#define TIMEOUT_STANDBY 6
@implementation DaemonState_Standby


- (DaemonState *)initWithDaemon:(Daemon *)d
{
    self = [super initWithDaemon:d];
    if(self)
    {
        randVal = GetDaemonRandomValue();
    }
    return self;
}

- (NSString *)name
{
    return @"Standby";
}

- (DaemonState *)eventUnknown:(int)prio randomValue:(long int)r
{
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventRemoteFailed
{
    [daemon actionSendTakeoverRequest:randVal];
    return [[DaemonState_TakeoverRequested alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverRequest:(int)prio randomValue:(long int)r
{
    [daemon actionSendTakeoverConfirm];
    return self;
}

- (DaemonState *)eventTakeoverConf:(int)prio
{
    if([daemon goToHot] == GOTO_HOT_FAILED)
    {
        [daemon actionSendFailed];
        [daemon actionSendStandby];
        [daemon goToStandby];
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverReject:(int)prio
{
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventStatusStandby:(int)prio
{
    /* both sides standby, this can't work. So we jump to hot */
    [daemon actionSendTakeoverRequest:randVal];
    return [[DaemonState_TakeoverRequested alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusHot:(int)prio
{
    /* we both agree on our roles. all fine */
    return self;
}

- (DaemonState *)eventTimer
{
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventTimeout
{
    [daemon actionSendTakeoverRequest:randVal];
    return [[DaemonState_TakeoverRequested alloc]initWithDaemon:daemon];
}

- (DaemonState *)localFailureIndication
{
    [daemon actionSendFailed];
    [daemon goToStandby];
    return self;
}

- (DaemonState *)localUnknownIndication
{
    [daemon actionSendStandby];
    [daemon goToStandby];
    return self;
}

- (DaemonState *)localStandbyIndication /* heartbeat from app */
{
    return self;
}

- (DaemonState *)localHotIndication /* heartbeat from app */
{
    [daemon actionSendStandby];
    [daemon goToStandby];
    return self;
}

@end
