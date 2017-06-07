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
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
    }
    else
    {
        [daemon actionSendTakeoverRequest];
    }
    return self;
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    if(!daemon.localIsFailed)
    {
        /* other side is failed. lets become master. */
        [daemon callActivateInterface];
        [daemon callStartAction];
        /* we dont send hot status here as we wait the application to confirm it with the status callbacks */
        return [[DaemonState_Hot alloc]initWithDaemon:daemon];
    }
    else
    {
        /* both sides failed */
        return self;
    }
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    return self;
}

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    return self;
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    daemon.localIsFailed = YES;
    [daemon actionSendFailed];
    return self;
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return self;
}


#pragma mark - Remote Commands
- (DaemonState *)eventTakeoverRequest:(NSDictionary *)dict
{
    [daemon actionSendTakeoverConfirm];
    return self;
}

- (DaemonState *)eventTakeoverConf:(NSDictionary *)dict
{
    /* somethings odd here */
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
        return self;
    }
    else
    {
        [daemon callActivateInterface];
        [daemon callStartAction];
        [daemon actionSendHot];
        return [[DaemonState_Hot alloc]initWithDaemon:daemon];
    }
    return self;
}

- (DaemonState *)eventTakeoverReject:(NSDictionary *)dict
{
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
    }
    else
    {
        [daemon actionSendStandby];
    }
    return self;
}


#pragma mark - Timer Events

- (DaemonState *)eventTimer
{
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
    }
    else
    {
        [daemon actionSendStandby];
    }
    return self;
}

- (DaemonState *)eventTimeout
{
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
        return self;
    }
    else
    {
        [daemon callActivateInterface];
        [daemon callStartAction];
        return [[DaemonState_Hot alloc]initWithDaemon:daemon];
    }
}

@end
