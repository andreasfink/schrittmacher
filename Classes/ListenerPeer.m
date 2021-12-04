//
//  ListenerPeerr.m
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "ListenerPeer.h"
#import "Daemon.h"
#import "ListenerLocal.h"

@implementation ListenerPeer

- (ListenerPeer *)init
{
    return [self initWithName:@"listener-peer" workSleeper:NULL];
}


- (ListenerPeer *)initWithName:name workSleeper:(UMSleeper *)ws
{
    self = [super initWithName:name workSleeper:ws];
    if(self)
    {
        _listenerType = [NSString stringWithFormat:@"(%@)",name];
    }
    return self;
}


- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p
{
    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e;
    int af;
    NSString *s = [UMSocket deunifyIp:addr type:&af];
    e = [_txSocket sendData:d toAddress:s toPort:p];
    [self.logFeed debug:e withText:[NSString stringWithFormat:@"TX %@:%d: %@",addr,p,msg]];

    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        NSString *s1 = [NSString stringWithFormat:@"TX Error %d: %@ while sending to %@:%d",e,s,addr,p];
        [self.logFeed majorError:e withText:s1];
        _lastError = s1;
    }
}

- (void)start
{
    _listenerType =@"(peer)";
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
            NSString *s = [NSString stringWithFormat:@"Can not bind txSocket to local ip %@ port %d. err = %d",_localAddress,_localPort,err];
            _lastError = s;
            NSLog(@"%@",s);
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
            NSString *s = [NSString stringWithFormat:@"Can not bind rxSocket to address %@ port %d. err = %d",_localAddress,_localPort,err];
            _lastError = s;
            NSLog(@"%@",s);
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

- (void)backgroundExit
{
    _lastError = @"listenerPeer terminated";
    NSLog(@"%@",_lastError);
}


- (void)receiveStatus:(NSData *)statusData
          fromAddress:(NSString *)address
                 port:(int)port
{
    if(     ([address isEqualToString:@"127.0.0.1"])
        ||  ([address isEqualToString:@"::1"]) )
    {
        [_listenerLocal receiveStatus:statusData
                          fromAddress:address
                                 port:port];
    }
    else
    {
        [super receiveStatus:statusData
                 fromAddress:address
                        port:port];
    }
}
@end
