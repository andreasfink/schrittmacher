//
//  DaemonState_Hot.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonState_all.h"

@implementation DaemonState_Hot


- (DaemonState *)initWithDaemon:(Daemon *)d
{
    self = [super initWithDaemon:d];
    if(self)
    {
        [daemon goToHot];
        [daemon actionSendHot];
    }
    return self;
}

- (NSString *)name
{
    return @"Hot";
}


- (DaemonState *)eventUnknown:(int)prio randomValue:(long int)r
{
    [daemon actionSendHot];
    return self;
}

- (DaemonState *)eventRemoteFailed
{
    [daemon actionSendHot];
    return self;
}


- (DaemonState *)eventTakeoverRequest:(int)prio
                          randomValue:(long int)r
{
    /* if we have lower priority, we always give in */
    if(prio > daemon.localPriority)
    {
        [daemon actionSendTakeoverConfirm];
        [daemon goToStandby];
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
    /* if we have hihger priority, we wont give in */
    /* if we have same priority, we dont want to change anything */
    [daemon actionSendTakeoverReject];
    return self;
}

- (DaemonState *)eventTakeoverConf:(int)prio
{
    return self;
}

- (DaemonState *)eventTakeoverReject:(int)prio
{
    [daemon goToStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusStandby:(int)prio
{
    return self;
}

- (DaemonState *)eventStatusHot:(int)prio
{
    /* other side says its in hot as well, we assume we are hot so we gotta challenge it */
    [daemon actionSendTakeoverRequest:randVal];
    return [[DaemonState_TakeoverRequested alloc]initWithDaemon:daemon];
}

- (DaemonState *)localFailureIndication
{
    [daemon actionSendFailed];
    [daemon goToStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localStandbyIndication /* heartbeat from app */
{
    [daemon actionSendFailed];
    [daemon goToStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localUnknownIndication /* heartbeat from app */
{
    [daemon goToHot];
    [daemon actionSendHot];
    return self;
}

- (DaemonState *)localHotIndication /* heartbeat from app */
{
    return self;
}

- (DaemonState *)eventTimer
{
    [daemon actionSendHot];
    return self;
}

- (DaemonState *)eventTimeout
{
    return self;
}

@end
