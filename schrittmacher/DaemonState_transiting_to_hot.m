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
        _goingHotStartTime = [NSDate date];
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
    [self logEvent:@"eventStatusRemoteHot"];
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteStandby"];
    /* we are already trying to go hot */
    return self;
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteFailure"];
    /* lets delay the battle until transition completed */
    return self;
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteFailover"];
    /* lets delay the battle until transition completed */
    return self;
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteUnknown"];
    /* we already transiting to hot, so the other side should believe its standby */
    [daemon actionSendTransitingToHot];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverRequest"];
    [daemon actionSendTakeoverConfirm];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverConf"];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverReject"];
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTransitingToHot"];
    /* we both want to go to hot. so we have to agree who wins */
    [daemon actionSendTakeoverRequest];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTransitingToStandby"];

    /* correct state */
    return self;
}


#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    [self logEvent:@"eventStatusLocalHot"];
    daemon.localIsFailed = NO;
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalStandby"];
    daemon.localIsFailed = NO;
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalFailure"];
    if([[NSDate date] timeIntervalSinceDate:_goingHotStartTime] > daemon.goingHotTimeout)
    {
        [daemon actionSendFailed];
        [daemon callStopAction];
        [daemon callDeactivateInterface];
        return [[DaemonState_Failed alloc]initWithDaemon:daemon];
    }
    return self;
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalUnknown"];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}


- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalTransitingToStandby"];
   [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalTransitingToHot"];
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
    if(daemon.localIsFailed)
    {
        return self;
    }
    [daemon actionSendTakeoverRequestForced];
    return self;
}

#pragma mark - Timer Events

- (DaemonState *)eventHeartbeat
{
    [self logEvent:@"eventHeartbeat"];
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
