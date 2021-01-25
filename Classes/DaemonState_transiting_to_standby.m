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
    return self;
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* the other side is standby and we are on the way to standby. Can not be. lets reverse course */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    /* the other side is dead and we are on the way to standby. Can not be. lets reverse course */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    /* the other side is wanting us to be hot. lets do it */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    /* we already transiting to standby, so the other side should believe it should go hot */
    [daemon actionSendTransitingToStandby];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    /* they are challenging us. So we agree to go standby */
    [daemon actionSendTakeoverConfirm];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    /* there has been a callenge and we are the winner. so we must go to hot now */
    [daemon actionSendTransitingToHot];
    [daemon callActivateInterface];
    [daemon callStartAction];
    return [[DaemonState_transiting_to_hot alloc]initWithDaemon:daemon];
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
    /* fine with me */
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [daemon actionSendTakeoverRequest];
    /* both sides want to go to standby? not a good idea */
    return self;
}

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    [daemon actionSendTakeoverRequest];
    return self;
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    [daemon actionSendFailed];
    [daemon callDeactivateInterface];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}




#pragma mark - GUI

- (DaemonState *)eventForceFailover:(NSDictionary *)dict
{
    [daemon actionSendFailover];
    [daemon callStopAction];
    [daemon callDeactivateInterface];
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

- (DaemonState *)eventTimer
{
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
