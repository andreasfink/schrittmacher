//
//  ListenerPeer4.h
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "Listener.h"


@interface ListenerPeer4 : Listener
{
    UMSocket *_txSocket4;
}
- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p;
- (void) attachDaemonIPv4:(Daemon *)d;

@end
