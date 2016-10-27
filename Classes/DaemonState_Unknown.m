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
        randVal = GetDaemonRandomValue();
    }
    return self;
}

- (NSString *)name
{
    return @"Unknown";
}

- (DaemonState *)eventStart
{
    [daemon actionSendUnknown:randVal];
    return self;
}

- (DaemonState *)eventUnknown:(int)prio
                  randomValue:(DaemonRandomValue)r
{
    return  [[DaemonState_TakeoverRequested alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventRemoteFailed
{
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverRequest:(int)prio randomValue:(long int)r
{
    [daemon actionSendTakeoverConfirm];
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
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
    [daemon actionSendUnknown:randVal];
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
