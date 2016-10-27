//
//  SchrittmacherClient.m
//  schrittmacher
//
//  Created by Andreas Fink on 26/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "SchrittmacherClient.h"

@implementation SchrittmacherClient

@synthesize resourceId;

- (SchrittmacherClient *)init
{
    self = [super init];
    if(self)
    {
        addressType = 4;
        localHost = [[UMHost alloc]initWithAddress:@"127.0.0.1"];
        port = 7700; /* default port */
    }
    return self;
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
    uc.localHost =  localHost;
    uc.localPort = 0;
    uc.remotePort = port;
    uc.RemoteHost = localHost;
    
    UMSocketError err = [uc bind];
    if (![uc isBound] )
    {
        @throw([NSException exceptionWithName:@"udp"
                                       reason:@"can not bind"
                                     userInfo:@{ @"port": @(0),
                                                 @"socket-err": @(err),
                                                 @"host" : localHost}]);
    }
 }


- (void)sendStatus:(NSString *)status
{
    NSDictionary *dict = @{ @"resource" : self.resourceId,
                            @"status"   : status,
                            @"priority" : @(0),
                            @"random"   : @(0)};
    
    NSString *msg = [dict jsonString];
    NSLog(@"TX: %@",dict);

    const char *utf8 = msg.UTF8String;
    size_t len = strlen(utf8);
    NSData *d = [NSData dataWithBytes:utf8 length:len];
    UMSocketError e = [uc sendData:d toAddress:@"127.0.0.1" toPort:port];
    if(e)
    {
        NSString *s = [UMSocket getSocketErrorString:e];
        NSLog(@"TX Error %d: %@",e,s);
    }
}

-(void)heartbeat:(BOOL)imHot
{
    if(imHot)
    {
        [self sendStatus:MESSAGE_LOCAL_HOT];
    }
    else
    {
        [self sendStatus:MESSAGE_LOCAL_STDBY];
    }
}

-(void)notifyFailure
{
    [self sendStatus:MESSAGE_LOCAL_FAIL];
}

@end

