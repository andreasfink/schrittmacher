//
//  DaemonState_Standby.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "DaemonState_all.h"

#define TIMEOUT_STANDBY 6
@implementation DaemonState_Standby

- (NSString *)name
{
    return @"Standby";
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    /* we both agree on our roles. all fine */
    return self;
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* both sides standby, this can't work. So we jump to hot IF WE CAN */
    if(daemon.localIsFailed == YES)
    {
        [daemon actionSendFailed];
        return [[DaemonState_Failed alloc]initWithDaemon:daemon];
    }
    else
    {
        [daemon actionSendTakeoverRequest];
    }
    return self;
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    DaemonState *nextState = self;
    if(daemon.localIsFailed==NO)
    {
        /* other side is failed. lets become master. */
        [daemon actionSendTransitingToHot];
        [daemon callActivateInterface];
        [daemon callStartAction];
        /* we dont send hot status here as we wait the application to confirm it with the status callbacks */
        nextState = [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
    }
    else
    {
        /* both sides failed */
        [daemon actionSendFailed];
        nextState = [[DaemonState_Failed alloc]initWithDaemon:daemon];
    }
    return nextState;
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    if(!daemon.localIsFailed)
    {
        /* other side wants to fail over. lets become master. */
        [daemon actionSendTransitingToHot];
        [daemon callActivateInterface];
        [daemon callStartAction];
        /* we dont send hot status here as we wait the application to confirm it with the status callbacks */
        return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
    }
    else
    {
        /* both sides failed */
        [daemon actionSendFailed];
        return [[DaemonState_Failed alloc]initWithDaemon:daemon];
    }
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    [daemon actionSendTakeoverConfirm];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    /* somethings odd here */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}


- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    /* somethings odd here */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}


#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    daemon.localIsFailed = NO;
    /* local app tells us its hot while we have agreed with remote to be standby. lets switch off local.*/
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    daemon.localIsFailed = NO;
    NSDate *now = [NSDate date];
    if(daemon.lastStandbySent==NULL)
    {
        [daemon actionSendStandby];
    }
    else
    {
        /* avoid sending standby more than once per second if nothing changed */
        NSTimeInterval elapsed = [now timeIntervalSinceDate:daemon.lastStandbySent];
        if(elapsed > 1)
        {
            [daemon actionSendStandby];
        }
    }
    return self;
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    daemon.localIsFailed = YES;
    [daemon actionSendFailed];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}


- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return self;
}


#pragma mark - GUI

- (DaemonState *)eventForceFailover:(NSDictionary *)dict
{
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    [daemon actionSendFailover];
    return self;
}

- (DaemonState *)eventForceTakeover:(NSDictionary *)dict
{
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
        return self;
    }
    [daemon actionSendTakeoverRequestForced];
    return self;
}

#pragma mark - Timer Events

/* heartbeat timer called */
- (DaemonState *)eventHeartbeat
{
    [daemon actionSendStandby];
    return self;
}

@end
