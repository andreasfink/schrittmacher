//
//  ListenerLocal4.m
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "ListenerLocal.h"
#import "Daemon.h"

@implementation ListenerLocal


- (void) attachDaemon:(Daemon *)d
{
    _daemons[d.resourceId] = d;
}

- (void)start
{
    _listenerType =@"(local)";
    @autoreleasepool
    {
        UMSocketError err;
        if(_localAddress.length > 0)
        {
            _rxSocket              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP];
            [_rxSocket setIPDualStack];
            _rxSocket.localPort    = _localPort;
            _rxSocket.localHost    = [[UMHost alloc] initWithAddress:_localAddress];
            NSLog(@"binding ListenerLocal to %@ on port %d",_localAddress,_localPort);
            err = [_rxSocket bind];
            if(err)
            {
                NSString *s = [NSString stringWithFormat:@"Can not bind ListenerLocal to udp port %d. err = %d",_localPort,err];
                _lastError = s;
                NSLog(@"%@",s);
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

- (void)backgroundExit
{
    _lastError = @"listenerLocal terminated";
    NSLog(@"%@",_lastError);
}

@end
