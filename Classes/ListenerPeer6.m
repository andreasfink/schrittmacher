//
//  ListenerPeer6.m
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "ListenerPeer6.h"
#import "Daemon.h"
@implementation ListenerPeer6


- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p
{
    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e;
    int af;
    NSString *s = [UMSocket deunifyIp:addr type:&af];
    e = [_txSocket6 sendData:d toAddress:s toPort:p];
    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        [self.logFeed majorError:e withText:[NSString stringWithFormat:@"TX Error %d: %@ while sending to %@:%d",e,s,addr,p]];
    }
}

- (void)start
{
    if(_txSocket6== NULL)
    {
        _txSocket6              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
        _txSocket6.localPort    = 0;
        _txSocket6.localHost    = [[UMHost alloc] initWithAddress:_localAddress];
        _txSocket6.remotePort    = _remotePort;
        _txSocket6.remoteHost    = [[UMHost alloc] initWithAddress:_peerAddress];

        UMSocketError err;
        NSLog(@"binding txSocket6 to %@",_localAddress);
        err = [_txSocket6 bind];
        if(err)
        {
            NSLog(@"udp can not bind txSocket6 err = %d",err);
        }
    }
    [super start];
}


- (void) attachDaemonIPv6:(Daemon *)d
{
    @synchronized(_daemons)
    {
        _daemons[d.resourceId] = d;
        d.listener6 = self;
    }
}
@end

