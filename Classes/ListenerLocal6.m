//
//  ListenerLocal6.m
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "ListenerLocal6.h"
#import "Daemon.h"

@implementation ListenerLocal6



- (void) attachDaemonIPv6:(Daemon *)d
{
    _daemons[d.resourceId] = d;
}

@end
