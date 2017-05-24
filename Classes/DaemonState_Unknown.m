//
//  DaemonState_Unknown.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonState_all.h"

@implementation DaemonState_Unknown


- (DaemonState_Unknown *)initWithDaemon:(Daemon *)d
{
    self = [super initWithDaemon:d];
    if(self)
    {
        d.randVal = GetDaemonRandomValue();
    }
    return self;
}

- (NSString *)name
{
    return @"Unknown";
}

- (DaemonState *)eventStart
{
    daemon.randVal = GetDaemonRandomValue();
    [daemon actionSendUnknown:daemon.randVal];
    return self;
}

- (DaemonState *)eventUnknown:(int)prio
                  randomValue:(DaemonRandomValue)r
{
    /* the other side doesnt know its state neither.
     Lets start the negotiations */
    daemon.randVal = GetDaemonRandomValue();
    [daemon actionSendTakeoverRequest:daemon.randVal];
    return  [[DaemonState_TakeoverRequested alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventRemoteFailed
{
    int r1 = [daemon callActivateInterface];
    int r2 = [daemon callStartAction];

    if((r1==0) && (r2==0))
    {
        [daemon startTransitingToHotTimer];
        return [[DaemonState_Unknown_transiting_to_Hot alloc]initWithDaemon:daemon];
    }
    else
    {
        [daemon startTransitingToStandbyTimer];
        return [[DaemonState_Unknown_transiting_to_Standby alloc]initWithDaemon:daemon];
    }
}

- (DaemonState *)eventTakeoverRequest:(int)prio randomValue:(long int)r
{
    [daemon actionSendTakeoverConfirm];
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Unknown_transiting_to_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverConf:(int)prio
{
    [daemon actionSendFailed];
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverReject:(int)prio
{
    [daemon actionSendFailed];
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusStandby:(int)prio
{
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusHot:(int)prio
{
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTimer
{
    [daemon actionSendUnknown:daemon.randVal];
    return self;
}

- (DaemonState *)eventTimeout
{
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}


- (DaemonState *)localFailureIndication
{
    [daemon actionSendFailed];
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localStandbyIndication /* heartbeat from app */
{
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localUnknownIndication /* heartbeat from app */
{
    return self;
}

- (DaemonState *)localHotIndication /* heartbeat from app */
{
    [daemon goToHot];
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
    return self;
}


@end
