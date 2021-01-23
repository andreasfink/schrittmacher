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
    [daemon actionSendHot];
    return self;
}

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    [daemon actionSendHot];
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [daemon actionSendStandby];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    daemon.localIsFailed = YES;
    [daemon actionSendFailed];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

#pragma mark - Remote Commands
- (DaemonState *)eventTakeoverRequest:(NSDictionary *)dict
{
    [daemon actionSendTakeoverConfirm];
    [daemon callDeactivateInterface];
    [daemon callStopAction];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
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
        //[daemon actionSendHot];
        // hot is being sent once local instance confirms "hot" status.
        _goingHot = [NSDate date];
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

- (DaemonState *)eventTimer
{
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
    }
    else
    {
        /* we have sent a takeover request and got confirmation. app now tells us its still standby */
        /* if its longer than 3 timer intervalls (which is 2sec), we tell the other side */
        if(_goingHot)
        {
            if([[NSDate date] timeIntervalSinceDate:_goingHot] > 6.0)
            {
               _goingHot = NULL;
               [daemon actionSendStandby];
            }
            else
            {
                /* we ignore the standby state as we might just have informed it a milisecond ago to go hot and it didnt had a chance to tell us it did yet */
            }
        }
        else
        {
            [daemon actionSendStandby];
        }
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
