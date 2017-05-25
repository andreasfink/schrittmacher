//
//  DaemonState_Hot_transiting_to_Standby.m
//  schrittmacher
//
//  Created by Andreas Fink on 24/05/2017.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "DaemonState_all.h"

@implementation DaemonState_Hot_transiting_to_Standby


- (NSString *)name
{
    return @"Hot_transiting_to_Standby";
}

- (DaemonState *)eventUnknown:(int)prio
                  randomValue:(long int)r
{
    /* the other side doesnt know if its hot or not. As we are about to go into standby, we just tell it we are standby */
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventRemoteFailed
{
    /* the other side asking for failover. 
     we consider ourselves standby already. So we fail miserably */
    [daemon actionSendStandby];
    return self;
}


- (DaemonState *)eventTakeoverRequest:(int)prio
                          randomValue:(long int)r
{
    /* we are transiting to standby so we agree on the other side being hot, no matter what */
    [daemon actionSendTakeoverConfirm];
    return self;
}

- (DaemonState *)eventTakeoverConf:(int)prio
{
    /* other side confirmed the takeover. So we should be hot now */
    /* but we are transiting to standby, so let them be hot. We send failover */
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventTakeoverReject:(int)prio
{
    /* the other side rejected our takeover. which is good as we are shutting down already */
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventStatusStandby:(int)prio
{
    /* other side says its in Standby. Let's PANIC */
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusHot:(int)prio
{
    /* other side says its in hot. All is fine */
    return self;
}

- (DaemonState *)localFailureIndication
{
    /* local daemon confirms failover. fine. now we are in standby */
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localStandbyIndication /* heartbeat from app */
{
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)localUnknownIndication /* heartbeat from app */
{
    /* local app doesnt know where it is at. lets tell it it is in standby */
    [daemon callStopAction];
    return self;
}

- (DaemonState *)localHotIndication /* heartbeat from app */
{
    /* no you are not hot! */
    [daemon callStopAction];
    return self;
}

- (DaemonState *)eventTimer
{
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventTimeout
{
    return self;
}

- (DaemonState *)eventToStandbyTimer
{
    /* local daemon has not answered in time, so we tell the other side we are standby */
    [daemon actionSendStandby];
    return [[DaemonState_Standby_LocalFailed alloc]initWithDaemon:daemon];
}

@end
