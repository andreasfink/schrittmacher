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
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
    [daemon actionSendUnknown];
    return self;
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    /* other side says its master. Then we shall be standby */
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* other side says its standby, so we must be hot */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    /* other side is failed. lets be master. */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    /* other side wants to fail over. lets be master. */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    /* the other side doesnt know its state neither. Lets start the negotiations */
    [daemon actionSendTakeoverRequest];
    return  self;
}

#pragma mark - Local Status

- (DaemonState *)eventStatusLocalHot:(NSDictionary *)dict
{
    /* if we are hot, the interface should be activated if not already */
    [daemon callActivateInterface];
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    /* we go straigth to standby if the local app tells us so */
    [daemon callDeactivateInterface];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    /* we fail, so other side should be master */
    [daemon actionSendFailed];
    [daemon callStopAction]; // local failure might also be caused by timeout */
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    /* we cant tell the local instance neither if we are active or not */
    /* but we should know soon  anyway */
    return  self;
}

#pragma mark - Remote Commands

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


- (DaemonState *)eventTimer
{
    [daemon actionSendUnknown];
    return self;
}

- (DaemonState *)eventTimeout
{
    /* other side doesnt answer. Lets panic and go straight to hot */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

@end
