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
    [self logEvent:@"eventStatusRemoteHot"];
    /* we both agree on our roles. all fine */
    return self;
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteStandby"];
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
    [self logEvent:@"eventStatusRemoteFailure"];
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
    [self logEvent:@"eventStatusRemoteFailover"];
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
    [self logEvent:@"eventStatusRemoteUnknown"];
   [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverRequest"];
   [daemon actionSendTakeoverConfirm];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverConf"];
    /* somethings odd here */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}


- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverReject"];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTransitingToHot"];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTransitingToStandby"];
    /* somethings odd here */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}


#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    [self logEvent:@"eventStatusLocalHot"];
    daemon.localIsFailed = NO;
    /* local app tells us its hot while we have agreed with remote to be standby. lets switch off local.*/
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    [daemon actionSendStandby];
    return self;
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalStandby"];
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
    [self logEvent:@"eventStatusLocalFailure"];
    daemon.localIsFailed = YES;
    [daemon actionSendFailed];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}


- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalUnknown"];
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalTransitingToStandby"];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalTransitingToHot"];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return self;
}


#pragma mark - GUI

- (DaemonState *)eventForceFailover:(NSDictionary *)dict
{
    [self logEvent:@"eventForceFailover"];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    [daemon actionSendFailover];
    return self;
}

- (DaemonState *)eventForceTakeover:(NSDictionary *)dict
{
    [self logEvent:@"eventForceTakeover"];
    if(!daemon.localIsFailed) /* only allow takeover if we are not failed */
    {
        [daemon actionSendTakeoverRequestForced];
    }
    return self;
}

#pragma mark - Timer Events

/* heartbeat timer called */
- (DaemonState *)eventHeartbeat
{
    [self logEvent:@"eventHeartbeat"];
    [daemon actionSendStandby];
    return self;
}

@end
