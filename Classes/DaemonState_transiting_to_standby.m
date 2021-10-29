//
//  DaemonState_transiting_to_standby.m
//  schrittmacher
//
//  Created by Andreas Fink on 23.01.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "DaemonState_transiting_to_standby.h"
#import "DaemonState_all.h"

@implementation DaemonState_transiting_to_standby

- (NSString *)name
{
    return @"transiting_to_standby";
}


- (DaemonState *)initWithDaemon:(Daemon *)d
{
    self = [super initWithDaemon:d];
    if(self)
    {
        _goingStandbyStartTime =[NSDate date];
    }
    return self;
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteHot"];
    return self;
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteStandby"];
    /* the other side is standby and we are on the way to standby. Can not be. lets reverse course */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteFailure"];
    /* the other side is dead and we are on the way to standby. Can not be. lets reverse course */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteFailover"];
    /* the other side is wanting us to be hot. lets do it */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteUnknown"];
    /* we already transiting to standby, so the other side should believe it should go hot */
    [daemon actionSendTransitingToStandby];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverRequest"];
    /* they are challenging us. So we agree to go standby */
    [daemon actionSendTakeoverConfirm];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverConf"];
    /* there has been a callenge and we are the winner. so we must go to hot now */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
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
    /* fine with me */
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTransitingToStandby"];
    [daemon actionSendTakeoverRequest];
    /* both sides want to go to standby? not a good idea */
    return self;
}

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    [self logEvent:@"eventStatusLocalHot"];
    /* local wants to be hot while we should go standby. nonono. */
    daemon.localIsFailed = YES;
    [daemon actionSendFailed];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalStandby"];
    daemon.localIsFailed = NO;
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalFailure"];
    [daemon actionSendFailed];
    [daemon callDeactivateInterface];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalUnknown"];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}


- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalTransitingToStandby"];
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
    [daemon actionSendFailover];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    return self;
}

- (DaemonState *)eventForceTakeover:(NSDictionary *)dict
{
    [self logEvent:@"eventForceTakeover"];
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
    [self logEvent:@"eventHeartbeat"];
    /* we are going hot but if it takes too long, we consider it failed */
    if([[NSDate date] timeIntervalSinceDate:_goingStandbyStartTime] > daemon.goingStandbyTimeout)
    {
        [daemon actionSendFailed];
        [daemon callDeactivateInterface];
        return [[DaemonState_Failed alloc]initWithDaemon:daemon];
    }
    [daemon actionSendTransitingToStandby];
    return self;
}

@end
