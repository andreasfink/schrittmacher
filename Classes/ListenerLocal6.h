//
//  ListenerLocal6.h
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "Listener.h"

@interface ListenerLocal6 : Listener

- (void) attachDaemonIPv6:(Daemon *)d;
- (void)start;
@end
