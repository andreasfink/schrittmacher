//
//  DaemonState_Hot_remoteFailed.m
//  schrittmacher
//
//  Created by Andreas Fink on 25.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "DaemonState_all.h"


@implementation DaemonState_Hot_RemoteFailure

- (NSString *)name
{
    return @"Hot-RemoteFailure";
}

#pragma mark - Remote Status

- (DaemonState *)eventStatusRemoteStandby:(NSDictionary *)dict
{
    /* other side says its back online */
    return [[DaemonState_Hot alloc]initWithDaemon:daemon];
}

- (DaemonState *)eventStatusRemoteFailure:(NSDictionary *)dict
{
    return self;
}

#pragma mark - Local Status


- (DaemonState *)eventStatusLocalStandby:(NSDictionary *)dict
{
    /* if the local process tells us it is in Standby but we think it was hot,
     then we must bring it back up whatsoever */

    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusLocalFailure:(NSDictionary *)dict
{
    /* if the local process tells us it is in Standby but we think it was hot,
     then we must bring it back up whatsoever */
    
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}

- (DaemonState *)eventStatusLocalUnknown:(NSDictionary *)dict
{
    /* Daemon says we are hot but  app doesnt know */
    [daemon callActivateInterface];
    [daemon callStartAction];
    return self;
}


@end
