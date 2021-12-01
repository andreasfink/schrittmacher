//
//  ListenerPeer6.h
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "Listener.h"


@interface ListenerPeer6 : Listener
{
    UMSocket *_txSocket6;
}
- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p;
- (void) attachDaemonIPv6:(Daemon *)d;
- (void)start;

@end
