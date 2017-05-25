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
        d.lastRx = [NSDate date];
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

- (DaemonState *)eventStatusRemoteUnknown:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventStatusRemoteUnknown"];
    return  [[DaemonState_Unknown alloc]initWithDaemon:daemon];
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

#pragma mark - Remote Commands

- (DaemonState *)eventTakeoverRequest:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventTakeoverRequest"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverConf:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventTakeoverConf"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTakeoverReject:(NSDictionary *)dict
{
    [daemon.logFeed warningText:@"Unexpected eventTakeoverReject"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

#pragma mark - Timer Events

- (DaemonState *)eventTimer
{
    [daemon.logFeed warningText:@"Unexpected eventTimer"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventTimeout
{
    [daemon.logFeed warningText:@"Unexpected eventTimeout"];
    return [[DaemonState_Unknown alloc]initWithDaemon:daemon];
}


#pragma mark - Helper Methods

- (int)takeoverChallenge:(NSDictionary *)dict;
{
    int prio    = [dict[@"priority"] intValue];
    int rremote = [dict[@"random"] intValue];
    

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

- (DaemonState *)eventToStandbyTimer
{
    NSLog(@"** Unexpected eventToStandbyTimer **");
    [daemon stopTransitingToStandbyTimer];
    return self;
}

- (DaemonState *)eventToHotTimer
{
    NSLog(@"** Unexpected eventToHotTimer **");
    [daemon stopTransitingToHotTimer];
    return self;
}

@end
