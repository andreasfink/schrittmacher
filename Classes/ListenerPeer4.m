//
//  ListenerPeer4.m
//  schrittmacher
//
//  Created by Andreas Fink on 01.12.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "ListenerPeer4.h"
#import "Daemon.h"

@implementation ListenerPeer4


- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p
{
    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e;
    int af;
    NSString *s = [UMSocket deunifyIp:addr type:&af];
    e = [_txSocket4 sendData:d toAddress:s toPort:p];
    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        [self.logFeed majorError:e withText:[NSString stringWithFormat:@"TX Error %d: %@ while sending to %@:%d",e,s,addr,p]];
    }
}

- (void)start
{
    if(_txSocket4== NULL)
    {
        _txSocket4              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP4ONLY];
        _txSocket4.localPort    = 0;
        _txSocket4.localHost    = [[UMHost alloc] initWithAddress:_localAddress];
        _txSocket4.remotePort    = _remotePort;
        _txSocket4.remoteHost    = [[UMHost alloc] initWithAddress:_peerAddress];

        UMSocketError err;
        NSLog(@"binding txSocket4 to %@",_localAddress);
        err = [_txSocket4 bind];
        if(err)
        {
            NSLog(@"udp can not bind txSocket4 err = %d",err);
        }
    }
    [super start];
}

- (void) attachDaemonIPv4:(Daemon *)d
{
    @synchronized(_daemons)
    {
        _daemons[d.resourceId] = d;
        d.listener4 = self;
    }
}

@end
