//
//  DameonState_Failed.m
//  schrittmacher
//
//  Created by Andreas Fink on 23.01.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "DaemonState_Failed.h"
#import "DaemonState_all.h"

@implementation DaemonState_Failed

- (NSString *)name
{
    return @"failed";
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    return self;
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* other sides wants to go to standby? lets remind them we are failed */
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    /* double failure. well...*/
    return self;
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    /* sorry, we cant help you */
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    /* sorry, we cant help you */
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    /* they are challenging us. So we agree to go standby */
    [daemon actionSendTakeoverConfirm];
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    [daemon actionSendTakeoverConfirm];
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    [daemon actionSendTakeoverConfirm];
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    /* fine with me */
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [daemon actionSendFailed];
    return self;
}

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    [daemon actionSendTakeoverRequest];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    return self;
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [daemon actionSendUnknown];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
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
    [daemon actionSendFailed];
    return self;
}

#pragma mark - Timer Events

- (DaemonState *)eventHeartbeat
{
    [daemon actionSendFailed];
    return self;
}


@end