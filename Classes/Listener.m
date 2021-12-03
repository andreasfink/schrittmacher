//
//  Listener.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "Listener.h"
#import "Daemon.h"

@implementation Listener

- (Listener *)init
{
    return [self initWithName:@"listener" workSleeper:NULL];
}

- (Listener *)initWithName:name workSleeper:(UMSleeper *)ws
{
    self = [super initWithName:name workSleeper:ws];
    if(self)
    {
        _daemons = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
}

- (void)receiveStatus:(NSData *)statusData
          fromAddress:(NSString *)address
{
 //   if(_logLevel <= UMLOG_DEBUG)
 //   {
        NSString *s = [NSString stringWithFormat:@"RX%@[%@] %@",_listenerType,address,statusData.stringValue];
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
                _lastMessage            = [NSString stringWithFormat:@"%@: %@",resource,status];
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

-(int) work
{
    if(_rxSocket==NULL)
    {
        _lastError = @"socket not available";
        return -1; /* terminates background task */
    }
    @autoreleasepool
    {
        return [self checkForPackets];
    }
}

- (int) checkForPackets
{
    UMAssert(_rxSocket!=NULL,@"_rxSocket can not be NULL");
    int packetsProcessed = 0;
    UMSocketError err =  [_rxSocket dataIsAvailable:2000];
    if((err == UMSocketError_has_data) || (err==UMSocketError_has_data_and_hup))
    {
        packetsProcessed += [self readDataFromSocket:_rxSocket];
    }
    else if((err!=UMSocketError_no_error) &&(err!=UMSocketError_no_data))
    {
        _lastError = [UMSocket getSocketErrorString:err];
        NSLog(@"Error %@ while reading from socket",_lastError);
        packetsProcessed = -1; /* terminates background task */
    }
    while(packetsProcessed>0);
    return packetsProcessed;
}

- (int)readDataFromSocket:(UMSocket *)socket
{
    if(socket==NULL)
    {
        return 0;
    }
    int packetsProcessed = 0;
    NSData  *data = NULL;
    NSString *address = NULL;
    int rxport;
    UMSocketError err2 = [socket receiveData:&data fromAddress:&address fromPort:&rxport];
    NSLog(@"RX: %@",data);
    if((err2 == UMSocketError_no_error) || (err2==UMSocketError_has_data) || (err2 == UMSocketError_has_data_and_hup))
    {
        if(data)
        {
            packetsProcessed++;
            [self receiveStatus:data fromAddress:address];
        }
    }
    else if((err2==UMSocketError_no_data) || (err2==UMSocketError_try_again))
    {
        
    }
    else
    {
        _lastError = [UMSocket getSocketErrorString:err2];
        NSLog(@"receiveData failed with error %d",err2);
    }
    return packetsProcessed;
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
