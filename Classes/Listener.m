//
//  Listener.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "Listener.h"
#import "Daemon.h"
#import "DaemonRandomValue.h"

@implementation Listener
@synthesize localHost;
@synthesize port;
@synthesize addressType;

- (Listener *)init
{
    self = [super init];
    if(self)
    {
        daemons =[[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)receiveStatus:(NSData *)statusData
{
    @autoreleasepool
    {
        UMJsonParser *parser = [[UMJsonParser alloc]init];
        id obj = [parser objectWithData:statusData];
        if([obj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dict  = obj;
            NSString *name      = [dict[@"resource"] stringValue];
            NSString *status    = [dict[@"status"] stringValue];
            int priority        = [dict[@"priority"] intValue];
            DaemonRandomValue r = (DaemonRandomValue)[dict[@"random"] longValue];
            NSLog(@"RX: %@",dict);

            Daemon *d = [self daemonByName:name];
            [d eventReceived:status
                withPriority:priority
                 randomValue:r];
        }
    }
}


- (void) attachDaemon:(Daemon *)d
{
    @synchronized(daemons)
    {
        daemons[d.resourceId] = d;
        d.listener = self;
    }
}

- (NSDictionary *)status
{
    @autoreleasepool
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];

        NSArray *allKeys;
        @synchronized(daemons)
        {
            allKeys =[daemons allKeys];
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
    if(addressType==6)
    {
        uc = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
    }
    else
    {
        uc = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP4ONLY];
    }

    uc.localHost = localHost;
    uc.localPort = port;
   // ucsender.localHost = localHost;
   // ucsender.localPort = port+1;

    UMSocketError err = [uc bind];
    if (![uc isBound] )
    {
        @throw([NSException exceptionWithName:@"udp"
                                       reason:@"can not bind"
                                     userInfo:@{ @"port":@(port),
                                                 @"socket-err": @(err),
                                                 @"host" : localHost}]);
    }
  /*
    err = [uc listen];
    if (![uc isListening] )
    {
        @throw([NSException exceptionWithName:@"udp"
                                       reason:@"can not listen"
                                     userInfo:@{ @"port":@(port),
                                                 @"socket-err": @(err),
                                                 @"host" : localHost}]);
    }
*/
    
    
    NSArray *allKeys;
    @synchronized(daemons)
    {
        allKeys =[daemons allKeys];
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

- (void) checkForPackets
{
    UMSocketError err;
    int receivePollTimeoutMs = 100;
    do
    {
        @autoreleasepool
        {
            err = [uc dataIsAvailable:receivePollTimeoutMs];

            if(err == UMSocketError_has_data)
            {
                NSData  *data = NULL;
                NSString *address = NULL;
                int rxport;
                UMSocketError err2 = [uc receiveData:&data fromAddress:&address fromPort:&rxport];
                if(err2 == UMSocketError_no_error)
                {
                    if(data)
                    {
                        [self receiveStatus:data];
                    }
                }
            }
        }
    } while(err == UMSocketError_has_data);
}

- (void)checkForTimeouts
{
    NSArray *allKeys;
    @synchronized(daemons)
    {
        allKeys =[daemons allKeys];
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

- (void)heartbeat
{
    NSArray *allKeys;
    @synchronized(daemons)
    {
        allKeys =[daemons allKeys];
    }
    for(NSString *key in allKeys)
    {
        Daemon *d = [self daemonByName:key];
        if(d)
        {
            [d eventTimer];
        }
    }
}


- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p
{
    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e = [uc sendData:d toAddress:addr toPort:p];
    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        NSLog(@"TX Error %d: %@",e,s);
    }
}

- (void)failover:(NSString *)name
{
    Daemon *d = [self daemonByName:name];
    [d eventForceFailover];
}

- (Daemon *)daemonByName:(NSString *)name
{
    Daemon *d;
    @synchronized(daemons)
    {
        d = daemons[name];
    }
    return d;
}

- (void)checkIfUp
{
    NSArray *allKeys;
    @synchronized(daemons)
    {
        allKeys =[daemons allKeys];
    }
    for(NSString *key in allKeys)
    {
        Daemon *d = [self daemonByName:key];
        if(d)
        {
            [d checkIfUp];
        }
    }
}
@end
