//
//  DaemonState_Hot.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "DaemonState_all.h"

@implementation DaemonState_Hot


- (NSString *)name
{
    return @"Hot";
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    /* other side says its in hot as well, we assume we are hot so we gotta challenge it */
    [daemon actionSendTakeoverReject];
    [daemon actionSendHot];
    return self;
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* other side says its in Standby. Everything is fine */
    return self;
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    /* the other side is telling it failed. we consider ourselves hot already so all is fine */
    return self;
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    /* the other side is telling it wants to fail over. we consider ourselves hot already so all is fine */
    return self;
}


- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    /* the other side doesnt know if its hot or not. As we are, we just tell it */
    [daemon actionSendHot];
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    /* the other side indicates it wants to challenge our hot status because it is assuming itself hot too */
    int i = [self takeoverChallenge:dict];
    if(i>0) /* we win */
    {
        [daemon actionSendTakeoverReject];
        return self;
    }
    else /* they win */
    {
        [daemon callStopAction];
        [daemon callDeactivateInterface];
        [daemon actionSendTakeoverConfirm];
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    /* other side confirmed the takeover. So we are definitively hot now */
    [daemon callActivateInterface]; /* just in case */
    [daemon callStartAction];       /* just in case */
    return self;
}

- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    /* the other side rejected our takeover. We should not be in Hot state already however */
    /* to mitigate, we transit to standby now */
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    [daemon actionSendStandby];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    [daemon actionSendTakeoverReject];
    [daemon actionSendHot];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [daemon actionSendHot];
    return self;
}

#pragma mark - Local Status
- (DaemonState *)eventStatusLocalHot:(NSDictionary *)pdu
{
    /* we both agree we're hot. all is fine */
    daemon.localIsFailed = NO;
    NSDate *now = [NSDate date];
    if(daemon.lastHotSent==NULL)
    {
        [daemon actionSendHot];
    }
    else
    {
        /* avoid sending hot more than once per second if nothing changed */
        NSTimeInterval elapsed = [now timeIntervalSinceDate:daemon.lastHotSent];
        if(fabs(elapsed) > 1)
        {
            [daemon actionSendHot];
        }
    }
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
    /* woot, we are not hot yet? */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    /* if the local process tells us it goes into Standby but we think it should be hot, we tell it to go hot */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
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
    /* we gotta shutdown the virtual interface before telling the other side to take over */
    /* Note: as we are told by the local process it went to failed,                       */
    /* there is no need to signal it to go standby                                        */
    /* as we dont wait confirmation from the local process                                */
    [daemon callDeactivateInterface];
    [daemon actionSendFailed];
    [daemon callStopAction];
    return [[DaemonState_Failed alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    /* Daemon says we are hot but app doesnt know */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return  self;
}


#pragma mark - GUI

- (DaemonState *)eventForceFailover:(NSDictionary *)dict
{
    [daemon callStopAction];
    [daemon callDeactivateInterface];
    [daemon actionSendFailover];
    return [[DaemonState_Standby alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventForceTakeover:(NSDictionary *)dict
{
    if(daemon.localIsFailed)
    {
        [daemon actionSendFailed];
        return [[DaemonState_Standby alloc]initWithDaemon:daemon];
    }
    [daemon actionSendHot];
    return self;
}



#pragma mark - Timer Events


/* heartbeat timer called */
- (DaemonState *)eventHeartbeat
{
    [daemon actionSendHot];
    return self;
}


@end
