//
//  ListenerPeer.h
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "Listener.h"

@class ListenerLocal;

@interface ListenerPeer : Listener
{
    UMSocket *_txSocket;
    ListenerLocal *_listenerLocal;
}

@property(readwrite,atomic,strong)   ListenerLocal *listenerLocal;

- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p;
- (void) attachDaemon:(Daemon *)d;
- (void)start;

@end
