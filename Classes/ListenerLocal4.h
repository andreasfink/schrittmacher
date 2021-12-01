//
//  ListenerLocal4.h
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "Listener.h"

@interface ListenerLocal4 : Listener

- (void) attachDaemonIPv4:(Daemon *)d;

@end

