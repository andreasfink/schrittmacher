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

- (void)start
{
    @autoreleasepool
    {
        UMSocketError err;
        if(_localAddress.length > 0)
        {
            _rxSocket              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
            _rxSocket.localPort    = _localPort;
            _rxSocket.localHost    = [[UMHost alloc] initWithAddress:_localAddress];
            NSLog(@"binding ListenerLocal6 to %@ on port %d",_localAddress,_localPort);
            err = [_rxSocket bind];
            if(err)
            {
                NSLog(@"udp can not bind ListenerLocal6 to port %d. err = %d",_localPort,err);
            }
        }

        NSArray *allKeys;
        @synchronized(_daemons)
        {
            allKeys =[_daemons allKeys];
        }
        for(NSString *key in allKeys)
        {
            Daemon *d = [self daemonByName:key];
            if(d)
            {
                [d actionStart];
            }
        }
    }
    [super startBackgroundTask];
}

@end
