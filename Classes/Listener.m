//
//  Listener.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "Listener.h"
#import "Daemon.h"
#include <poll.h>

@implementation Listener

- (Listener *)init
{
    self = [super init];
    if(self)
    {
        _daemons =[[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)receiveStatus:(NSData *)statusData
          fromAddress:(NSString *)address
{
    @autoreleasepool
    {
        @try
        {
            UMJsonParser *parser = [[UMJsonParser alloc]init];
            id obj = [parser objectWithData:statusData];
            if([obj isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *di = (NSDictionary *)obj;
                NSString *resource      = [di[@"resource"] stringValue];
                NSString *status    = [di[@"status"] stringValue];
                NSMutableDictionary *dict  = [di mutableCopy];
                dict[@"address"]    = address;
                dict[@"pdu"]        = statusData;

                Daemon *daemon = [self daemonByName:resource];
                if(daemon)
                {
                    [daemon eventReceived:status dict:dict];
                    if(_logLevel <= UMLOG_DEBUG)
                    {
                        [daemon.logFeed debugText:[NSString stringWithFormat:@"RX <-%@: %@",address,di]];
                    }
                }
                else
                {
                    [self.logFeed infoText:[NSString stringWithFormat:@"Ignoring unknown resource '%@'",resource]];
                }
            }
        }
        @catch(NSException *e)
        {
            [self.logFeed warningText:[NSString stringWithFormat:@"Exception: %@",e]];
        }
    }
}


- (void) attachDaemon:(Daemon *)d
{
    @synchronized(_daemons)
    {
        _daemons[d.resourceId] = d;
        d.listener = self;
    }
}

- (NSDictionary *)status
{
    @autoreleasepool
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];

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
                dict[key] = [d status];
            }
        }
        return dict;
    }
}

- (void)start
{
    @autoreleasepool
    {
        if(_addressType==6)
        {
            _rxSocket = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
            _txSocket = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
        }
        else
        {
            _rxSocket = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP4ONLY];
            _txSocket = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP4ONLY];
        }

        _rxSocket.localHost = [[UMHost alloc] initWithLocalhost];               /* im listening on all addresses */
        _rxSocket.localPort = _port;

        _txSocket.localHost = [[UMHost alloc] initWithAddress:_localAddress];   /* im sending out from specific address */
        _txSocket.localPort = 0;

        UMSocketError err = [_rxSocket bind];
        if (![_rxSocket isBound] )
        {
            @throw([NSException exceptionWithName:@"udp"
                                           reason:@"can not bind to publicIP"
                                         userInfo:@{ @"port":@(_port),
                                                     @"socket-err": @(err),
                                                     @"host" : _localHost}]);
        }

        err = [_txSocket bind];
        if (![_txSocket isBound] )
        {
            @throw([NSException exceptionWithName:@"udp"
                                           reason:@"can not bind to publicIP"
                                         userInfo:@{ @"port":@(_port),
                                                     @"socket-err": @(err),
                                                     @"host" : _localHost}]);
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
}

-(void)pollAction
{
    [self checkForPackets];
    [self checkForTimeouts];
}


- (void) checkForPackets
{
    BOOL packetsProcessed = NO;
    do
    {
        UMSocketError err;
        @autoreleasepool
        {
            err = [_rxSocket dataIsAvailable:0];
            if(err == UMSocketError_has_data)
            {
                NSData  *data = NULL;
                NSString *address = NULL;
                int rxport;
                UMSocketError err2 = [_rxSocket receiveData:&data fromAddress:&address fromPort:&rxport];
                if((err2 == UMSocketError_no_error) || (err2==UMSocketError_has_data) || (err2 == UMSocketError_has_data_and_hup))
                {
                    packetsProcessed = YES;
                    if(data)
                    {
                        [self receiveStatus:data fromAddress:address];
                    }
                }
                else
                {
                    NSLog(@"receiveData on public interface failed with error %d",err2);
                }
            }
        }
    }
    while(packetsProcessed);
}

- (void)checkForTimeouts
{
    @autoreleasepool
    {
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
                [d checkForTimeouts];
            }
        }
    }
}

- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p
{
    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e = [_txSocket sendData:d toAddress:addr toPort:p];
    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        [self.logFeed majorError:e withText:[NSString stringWithFormat:@"TX Error %d: %@",e,s]];
    }
}

- (void)failover:(NSString *)name
{
    @autoreleasepool
    {
        Daemon *d = [self daemonByName:name];
        [d eventForceFailover];
    }
}

- (void)takeover:(NSString *)name
{
    @autoreleasepool
    {
        Daemon *d = [self daemonByName:name];
        [d eventForceTakeover];
    }
}
- (Daemon *)daemonByName:(NSString *)name
{
    @autoreleasepool
    {
        Daemon *d;
        @synchronized(_daemons)
        {
            d = _daemons[name];
        }
        return d;
    }
}

@end
