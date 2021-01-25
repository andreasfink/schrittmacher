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
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteHot"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteStandby"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteFailure"];

    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailover:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteFailover"];

    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteUnknown"];
    return  [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverRequest:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventTakeoverRequest"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverConf:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventTakeoverConf"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTakeoverReject:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventTakeoverReject"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteTransitingToHot:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteTransitingToHot"];
    return self;
}

- (DaemonState *)eventStatusRemoteTransitingToStandby:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteTransitingToStandby"];
    return self;
}

#pragma mark - Local Status

- (DaemonState *)eventStatusLocalHot:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalHot"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalStandby"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalFailure"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalUnknown"];
    return  [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalTransitingToHot:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalTransitingToHot"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusLocalTransitingToStandby:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusLocalTransitingToStandby"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}


#pragma mark - GUI Commands Status

- (DaemonState *)eventForceFailover:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventForceFailover"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventForceTakeover:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventForceTakeover"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

#pragma mark - Timer Events

- (DaemonState *)eventHeartbeat
{
    [daemon.logFeed warningText:@"Unexpected eventHeartbeat"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventRemoteTimeout
{
    /* other side's daemon is dead */
    daemon.lastRemoteState = @"no-info-received";
    return [self eventStatusRemoteFailure:NULL];
}

- (DaemonState *)eventLocalTimeout
{
    /* this side's app is dead */
    daemon.lastLocalState = @"no-info-received";
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

@end
