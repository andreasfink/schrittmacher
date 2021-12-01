//
//  ListenerPeerr.m
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "ListenerPeer.h"
#import "Daemon.h"

@implementation ListenerPeer


- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p
{
    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e;
    int af;
    NSString *s = [UMSocket deunifyIp:addr type:&af];
    e = [_txSocket sendData:d toAddress:s toPort:p];
    [self.logFeed debug:e withText:[NSString stringWithFormat:@"TX %@:%d: %@",addr,p,msg]]:

    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        [self.logFeed majorError:e withText:[NSString stringWithFormat:@"TX Error %d: %@ while sending to %@:%d",e,s,addr,p]];
    }
}

- (void)start
{
    
    if(_txSocket== NULL)
    {
        _txSocket              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP];
        [_txSocket setIPDualStack];
        _txSocket.localPort    = 0;
        _txSocket.localHost    = [[UMHost alloc] initWithAddress:_localAddress];
        _txSocket.remotePort    = _remotePort;
        _txSocket.remoteHost    = [[UMHost alloc] initWithAddress:_peerAddress];

        UMSocketError err;
        NSLog(@"binding txSocket to %@",_localAddress);
        err = [_txSocket bind];
        if(err)
        {
            NSLog(@"udp can not bind txSocket err = %d",err);
        }
    }

    UMSocketError err;
    if(_localAddress.length > 0)
    {
        _rxSocket              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP];
        [_rxSocket setIPDualStack];
        _rxSocket.localPort    = _localPort;
        _rxSocket.localHost    = [[UMHost alloc] initWithAddress:_localAddress];
        NSLog(@"binding ListnerPeer to %@ on port %d",_localAddress,_localPort);
        err = [_rxSocket bind];
        if(err)
        {
            NSLog(@"udp can not bind ListenerPeer to port %d. err = %d",_localPort,err);
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
    [super startBackgroundTask];
}

- (void) attachDaemon:(Daemon *)d
{
    @synchronized(_daemons)
    {
        _daemons[d.resourceId] = d;
        d.listener = self;
    }
}

@end
