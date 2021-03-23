//
//  DaemonState_transiting_to_hot.m
//  schrittmacher
//
//  Created by Andreas Fink on 23.01.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "DaemonState_transiting_to_hot.h"
#import "DaemonState_all.h"

#define TIMEOUT_STANDBY 6

@implementation DaemonState_transiting_to_hot

- (DaemonState *)initWithDaemon:(Daemon *)d
{
    self = [super initWithDaemon:d];
    if(self)
    {
        _goingHotStartTime =[NSDate date];
    }
    return self;
}

- (NSString *)name
{
    return @"transiting_to_hot";
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* we are already trying to go hot */
    return self;
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    /* lets delay the battle until transition completed */
    return self;
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    /* lets delay the battle until transition completed */
    return self;
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    /* we already transiting to hot, so the other side should believe its standby */
    [daemon actionSendTransitingToHot];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    [daemon actionSendTakeoverConfirm];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    /* we both want to go to hot. so we have to agree who wins */
    [daemon actionSendTakeoverRequest];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    /* correct state */
    return self;
}


#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    daemon.localIsFailed = NO;
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    daemon.localIsFailed = NO;
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    [daemon actionSendFailed];
    [daemon callDeactivateInterface];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}


- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
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

- (DaemonState *)eventHeartbeat
{
    /* we are going hot but if it takes too long, we consider it failed */
    if([[NSDate date] timeIntervalSinceDate:_goingHotStartTime] > daemon.goingHotTimeout)
    {
        [daemon actionSendFailed];
        return [[DaemonState_Failed alloc]initWithDaemon:daemon];
    }
    [daemon actionSendTransitingToHot];
    return self;
}


@end
