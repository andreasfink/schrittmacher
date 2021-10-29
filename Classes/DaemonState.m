//
//  DaemonState.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "DaemonState.h"
#import "Daemon.h"
#import "DaemonState_all.h"

@implementation DaemonState

- (DaemonState *)initWithDaemon:(Daemon *)d
{
    self = [super init];
    if(self)
    {
        daemon = d;
        _logFeed = d.logFeed;
        d.lastRemoteRx = [NSDate date];
        d.lastLocalRx = [NSDate date];
    }
    return self;
}

- (NSString *)description
{
    return [self name];
}

- (NSString *)name
{
    return @"undefined";
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteHot"];
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteHot"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteStandby"];
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteStandby"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteFailure"];

    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteFailure"];

    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteFailover"];
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteFailover"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteUnknown"];
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteUnknown"];
    return  [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverRequest"];
    [daemon.logFeed warningText:@"Unexpected eventTakeoverRequest"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverConf"];
    [daemon.logFeed warningText:@"Unexpected eventTakeoverConf"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTakeoverReject"];
    [daemon.logFeed warningText:@"Unexpected eventTakeoverReject"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTransitingToHot"];
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteTransitingToHot"];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusRemoteTransitingToStandby"];
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteTransitingToStandby"];
    return self;
}

#pragma mark - Local Status

- (DaemonState *)eventStatusLocalHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalHot"];
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalHot"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalStandby"];
    daemon.localIsFailed = NO;
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalStandby"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalFailure"];
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalFailure"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalUnknown"];
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalUnknown"];
    return  [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalTransitingToHot"];
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalTransitingToHot"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    [self logEvent:@"eventStatusLocalTransitingToStandby"];
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalTransitingToStandby"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}


#pragma mark - GUI Commands Status

- (DaemonState *)eventForceFailover:(NSDictionary *)dict
{
    [self logEvent:@"eventForceFailover"];
    [daemon.logFeed warningText:@"Unexpected eventForceFailover"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventForceTakeover:(NSDictionary *)dict
{
    [self logEvent:@"eventForceTakeover"];
    [daemon.logFeed warningText:@"Unexpected eventForceTakeover"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

#pragma mark - Timer Events

- (DaemonState *)eventHeartbeat
{
    [self logEvent:@"eventHeartbeat"];
    [daemon.logFeed warningText:@"Unexpected eventHeartbeat"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventRemoteTimeout
{
    [self logEvent:@"eventRemoteTimeout"];
    /* other side's daemon is dead */
    ,[_currentState.name];
    daemon.lastRemoteMessage = @"event-remote-timeout";
    return [self eventStatusRemoteFailure:NULL];
}

- (DaemonState *)eventLocalTimeout
{
    [self logEvent:@"eventLocalTimeout"];
    /* this side's app is dead */
    daemon.lastLocalMessage = @"event-local-timeout";
    return [self eventStatusLocalFailure:NULL];
}

#pragma mark - Helper Methods

- (int)takeoverChallenge:(NSDictionary *)dict;
{
    int prio    = [dict[@"priority"] intValue];
    DaemonRandomValue rremote = [dict[@"random"] intValue];
    

    if(prio < daemon.localPriority)
    {
        return 1; /* we win */
    }
    else if(prio == daemon.localPriority)
    {
        if(daemon.randVal == rremote)
        {
            return 0;
        }
        if(daemon.randVal > rremote)
        {
            return 1;
        }
        return -1;
    }
    else
    {
        return -1;
    }
}

- (void)logEvent:(NSString *)event
{
    NSString *s = NSString stringWithFormat:@"%@/%@",self.name,event];
    [_daemon.logFeed infoText:s];
}

@end
