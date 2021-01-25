//
//  DaemonState_Unknown.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "DaemonState_all.h"

@implementation  DaemonState_Unknown


- (NSString *)name
{
    return @"Unknown";
}

- (DaemonState *)eventStart
{
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
        return [[DaemonState_Failed alloc]initWithDaemon:daemon];
    }
    [daemon actionSendUnknown];
    return self;
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    /* other side says its master. Then we shall be standby */
    [daemon actionSendStandby];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* other side says its standby, so we must be hot */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    /* other side is failed. lets be master. */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    /* other side wants to fail over. lets be master. */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    /* the other side doesnt know its state neither. Lets start the negotiations */
    [daemon actionSendTakeoverRequest];
    return  self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    /* other side says it wants to take over. let it happen */
    [daemon actionSendTransitingToStandby];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return [[DaemonState_transiting_to_standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    /* other side tells us we can take over. lets be master. */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    /* other side says it doesnt want us to to take over. let it happen */
    [daemon actionSendTransitingToStandby];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return [[DaemonState_transiting_to_standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    /* other side says it doesnt want us to to take over. let it happen */
    [daemon actionSendTransitingToStandby];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return [[DaemonState_transiting_to_standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    /* other side tells us we can take over. lets be master. */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

#pragma mark - Local Status

- (DaemonState *)eventStatusLocalHot:(NSDictionary *)dict
{
    /* if we are hot, the interface should be activated if not already */
    [daemon actionSendHot];
    [daemon callActivateInterface];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    /* we go straigth to standby if the local app tells us so */
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    /* we fail, so other side should be master */
    [daemon actionSendFailed];
    [daemon callStopAction]; // local failure might also be caused by timeout */
    [daemon callDeactivateInterface];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    /* we cant tell the local instance neither if we are active or not */
    /* but we should know soon  anyway */
    [daemon actionSendUnknown];
    return  self;
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
    /* local is reporting its going hot. Not sure if we should agree yet. lets enforce a challenge */
    [daemon actionSendTakeoverRequest];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    /* local is reporting its going standby. lets let the other side know */
    [daemon actionSendTransitingToStandby];
    return [[DaemonState_transiting_to_standby alloc]initWithDaemon:daemon];
}

#pragma mark - Commands

- (DaemonState *)eventTakeoverRequest:(NSDictionary *)dict
{
    /* other side is unknown too wants to be master. lets see if we agree */
    int i = [self takeoverChallenge:dict];
    if(i>0) /* we win */
    {
        [daemon actionSendTakeoverReject];
        return self;
    }
    else /* they win */
    {
        [daemon actionSendTakeoverConfirm];
        [daemon callStopAction];
        [daemon callDeactivateInterface];
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
}


- (DaemonState *)eventTakeoverConf:(NSDictionary *)dict
{
    /* other side agrees we should be master. lets be master then. */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverReject:(NSDictionary *)dict
{
    /* other side wants to be master. let it be so */
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

#pragma mark - GUI

- (DaemonState *)eventForceFailover:(NSDictionary *)dict
{
    [daemon actionSendFailover];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventForceTakeover:(NSDictionary *)dict
{
    [daemon actionSendTakeoverRequestForced];
    return self;
}


#pragma mark - Timer Events

/* heartbeat timer called */
- (DaemonState *)eventTimer
{
    [daemon actionSendUnknown];
    return self;
}

@end
