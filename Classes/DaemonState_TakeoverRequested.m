//
//  DaemonState_TakeoverRequested.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonState_all.h"

@implementation DaemonState_TakeoverRequested

- (DaemonState_TakeoverRequested *)initWithDaemon:(Daemon *)d
{
    self = [super initWithDaemon:d];
    if(self)
    {
        daemon.randVal = GetDaemonRandomValue();
    }
    return self;
}

- (NSString *)name
{
    return @"TakeoverRequested";
}


- (DaemonState *)eventUnknown:(int)prio randomValue:(long int)r
{
    if([daemon goToHot] == GOTO_HOT_FAILED)
    {
        [daemon goToStandby];
        [daemon actionSendStandby];
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventRemoteFailed
{
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}


- (DaemonState *)eventTakeoverRequest:(int)prio
                          randomValue:(long int)r
{
    
    int challenge = [self takeoverChallenge:prio remoteRandom:r localRandom: randVal];
    if(challenge == 0)
    {
        /* we have a tie. Lets try again with another random value */
        randVal = random();
        [daemon actionSendTakeoverRequest:randVal];
        return self;
    }
    else if(challenge > 0)
    {
        [daemon actionSendTakeoverReject];
        return [[DaemonState_Hot alloc]initWithDaemon:daemon];
    }
    else
    {
        [daemon actionSendTakeoverConfirm];
        [daemon goToStandby];
        [daemon actionSendStandby];
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
}

- (DaemonState *)eventTakeoverConf:(int)prio
{
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverReject:(int)prio
{
    [daemon actionSendStandby];
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusStandby:(int)prio
{
    [daemon actionSendTakeoverRequest:randVal];
    return self;
}

- (DaemonState *)eventStatusHot:(int)prio
{
    /* somethings odd here */
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTimer
{
    [daemon actionSendTakeoverRequest:randVal];
    return self;
}

- (DaemonState *)eventTimeout
{
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)localFailureIndication
{
    [daemon actionSendFailed];
    [daemon goToStandby];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localUnknownIndication
{
    return self;
}

- (DaemonState *)localStandbyIndication /* heartbeat from app */
{
    return self;
}

- (DaemonState *)localHotIndication /* heartbeat from app */
{
    return self;
}

@end
