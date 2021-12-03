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


- (ListenerLocal *)init
{
    return [self initWithName:@"listener-local" workSleeper:NULL];
}

- (ListenerLocal *)initWithName:name workSleeper:(UMSleeper *)ws
{
    self = [super initWithName:name workSleeper:ws];
    if(self)
    {
        _listenerType = [NSString stringWithFormat:@"(%@)",name];
    }
    return self;
}

- (void) attachDaemon:(Daemon *)d
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


@end
