//
//  Listener.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "Listener.h"
#import "Daemon.h"
//#include <poll.h>

@implementation Listener

- (Listener *)init
{
    self = [super initWithName:@"listener" workSleeper:NULL];
    if(self)
    {
        _daemons =[[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)receiveStatus:(NSData *)statusData
          fromAddress:(NSString *)address
{
 //   if(_logLevel <= UMLOG_DEBUG)
 //   {
        NSString *s = [NSString stringWithFormat:@"RX[%@] %@",address,statusData.stringValue];
        [_logFeed debugText:s];
 //   }
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
                NSString *status        = [di[@"status"] stringValue];
                long rx_pid             = [di[@"pid"] longValue];
                long adminweb_port         = [di[@"adminweb-port"] longValue];
                NSMutableDictionary *dict  = [di mutableCopy];
                dict[@"address"]    = address;
                dict[@"pdu"]        = statusData;
            
                Daemon *daemon = [self daemonByName:resource];
                if(daemon)
                {
                    if(rx_pid>0)
                    {
                        daemon.pid = rx_pid;
                    }
                    if(adminweb_port>0)
                    {
                        daemon.adminweb_port = adminweb_port;
                    }
                    [daemon eventReceived:status dict:dict];
                    if(_logLevel <= UMLOG_DEBUG)
                    {
                        [daemon.logFeed debugText:[NSString stringWithFormat:@"RX <-%@: %@",address,di]];
                    }
                }
                else
                {
                    [_logFeed infoText:[NSString stringWithFormat:@"Ignoring unknown resource '%@'",resource]];
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
        UMSocketError err;
        if(_localAddress4.length > 0)
        {
    
            _rxSocket4              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP];
            _rxSocket4.localPort    = _port;
            _rxSocket4.localHost    = [[UMHost alloc] initWithAddress:_localAddress4];
            NSLog(@"binding rxSocket4 to %@ on port %d",_localAddress4,_port);
            err = [_rxSocket4 bind];
            if(err)
            {
                NSLog(@"udp can not bind rxSocket4 to port %d. err = %d",_port,err);
                _rxSocket4 = NULL;
            }
        }
        
        if(_localAddress6.length > 0)
        {
            _rxSocket6              = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
            _rxSocket6.localPort    = _port;
            _rxSocket6.localHost    = [[UMHost alloc] initWithAddress:_localAddress6];
            NSLog(@"binding rxSocket6 to %@ on port %d",_localAddress6,_port);
            err = [_rxSocket6 bind];
            if(err)
            {
                NSLog(@"udp can not bind rxSocket6 to port %d. err = %d",_port,err);
                _rxSocket6 = NULL;
            }
        }
        
        if(_localAddress4.length > 0)
        {
            _txSocket4                  = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP4ONLY];
            _txSocket4.localPort        = 0;
            _txSocket4.localHost        = [[UMHost alloc] initWithAddress:_localAddress4];
            NSLog(@"binding txSocket4 to %@ on port 0",_localAddress4);
            err = [_txSocket4 bind];
            if(err)
            {
                NSLog(@"udp can not bind txSocket4 err=%d",err);
                _txSocket4 = NULL;
            }
        }
        
        if(_localAddress6.length > 0)
        {
            _txSocket6                  = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
            _txSocket6.localPort        = 0;
            _txSocket6.localHost        = [[UMHost alloc] initWithAddress:_localAddress6];
            NSLog(@"binding txSocket6 to %@ on port 0",_localAddress6);
            err = [_txSocket6 bind];
            if(err)
            {
                NSLog(@"udp can not bind txSocket6 err=%d",err);
                _txSocket6 = NULL;
            }
        }
        
        _rxSocketLocal4             = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
        _rxSocketLocal4.localPort   = _port;
        _rxSocketLocal4.localHost   = [[UMHost alloc] initWithAddress:@"ipv4:127.0.0.1"];
        NSLog(@"binding txSocket4 to 127.0.0.1 on port %d",_port);
        err = [_rxSocketLocal4 bind];
        if(err)
        {
            NSLog(@"udp can not bind _rxSocketLocal4 err=%d",err);
            _rxSocketLocal4 = NULL;
        }

        _rxSocketLocal6             = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP6ONLY];
        _rxSocketLocal6.localPort   = _port;
        _rxSocketLocal6.localHost   = [[UMHost alloc] initWithAddress:@"ipv6::1"];
        NSLog(@"binding txSocket6 to ::1 on port %d",_port);
        err = [_rxSocketLocal6 bind];
        if(err)
        {
            NSLog(@"udp can not bind _rxSocketLocal6 err=%d",err);
            _rxSocketLocal6 = NULL;
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

-(int) work
{
    int packetsProcessed = [self checkForPackets];
    if(packetsProcessed==0)
    {
        if(packetsProcessed==0)
        {
            usleep(100000); /* sleep 100ms */
        }
    }
    return packetsProcessed;
}

- (int) checkForPackets
{
    int packetsProcessed = 0;
    do
    {
        UMSocketError err;
        @autoreleasepool
        {
            err = UMSocketError_no_error;
            if(_rxSocket4)
            {
                err = [_rxSocket4 dataIsAvailable:0];
                if(err == UMSocketError_has_data)
                {
                    packetsProcessed += [self readDataFromSocket:_rxSocket4];
                }
            }
            if(_rxSocket6)
            {
                err = [_rxSocket6 dataIsAvailable:0];
                if(err == UMSocketError_has_data)
                {
                    packetsProcessed += [self readDataFromSocket:_rxSocket6];
                }
            }
            if(_rxSocketLocal4)
            {
                err = [_rxSocketLocal4 dataIsAvailable:0];
                if(err == UMSocketError_has_data)
                {
                    packetsProcessed += [self readDataFromSocket:_rxSocketLocal4];
                }
            }
            if(_rxSocketLocal6)
            {
                err = [_rxSocketLocal6 dataIsAvailable:0];
                if(err == UMSocketError_has_data)
                {
                    packetsProcessed += [self readDataFromSocket:_rxSocketLocal6];
                }
            }
        }
    }
    while(packetsProcessed>0);
    return packetsProcessed;
}

- (int)readDataFromSocket:(UMSocket *)socket
{
    int packetsProcessed = 0;
    NSData  *data = NULL;
    NSString *address = NULL;
    int rxport;
    UMSocketError err2 = [socket receiveData:&data fromAddress:&address fromPort:&rxport];
    NSLog(@"RX: %@",data);
    if((err2 == UMSocketError_no_error) || (err2==UMSocketError_has_data) || (err2 == UMSocketError_has_data_and_hup))
    {
        packetsProcessed++;
        if(data)
        {
            [self receiveStatus:data fromAddress:address];
        }
    }
    else if((err2==UMSocketError_no_data) || (err2==UMSocketError_try_again))
    {
        
    }
    else
    {
        NSLog(@"receiveData failed with error %d",err2);
    }
    return packetsProcessed;
}

- (void)sendString:(NSString *)msg toAddress:(NSString *)addr toPort:(int)p
{
    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e;
    int af;
    NSString *s = [UMSocket deunifyIp:addr type:&af];
    if(af==6)
    {
        NSLog(@"addr6=%@/%@",addr,s);
        e = [_txSocket6 sendData:d toAddress:s toPort:p];

    }
    else
    {
        NSLog(@"addr4=%@/%@",addr,s);
        e = [_txSocket4 sendData:d toAddress:s toPort:p];
    }
    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        [self.logFeed majorError:e withText:[NSString stringWithFormat:@"TX Error %d: %@ while sending to %@:%d",e,s,addr,p]];
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
