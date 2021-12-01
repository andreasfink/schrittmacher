//
//  ListenerLocal4.m
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "ListenerLocal4.h"
#import "Daemon.h"

@implementation ListenerLocal4


- (void) attachDaemonIPv4:(Daemon *)d
{
    _daemons[d.resourceId] = d;
}

@end
