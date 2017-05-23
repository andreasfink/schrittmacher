//
//  AppDelegate.m
//  schrittmacher
//
//  Created by Andreas Fink on 20/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "AppDelegate.h"
#include <unistd.h>

#import  <ulib/ulib.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <stdlib.h>

#import "Listener.h"
#import "Daemon.h"
#import "NSString+urlencode.h"

extern int  global_argc;
extern char **global_argv;

@implementation AppDelegate

@synthesize config;

AppDelegate *_global_appdel= NULL;

+ (AppDelegate *)sharedInstance
{
    if(_global_appdel)
    {
        return _global_appdel;
    }
    return [[AppDelegate alloc]init];
}

- (AppDelegate *)init
{
    if(_global_appdel)
    {
        return _global_appdel;
    }
    self =[super init];
    if (self)
    {
        _global_appdel = self;
        time(&g_startup_time);
        int threadCount = ulib_cpu_count();
        mainTaskQueue =[[UMTaskQueue alloc]initWithNumberOfThreads:threadCount name:@"mainTaskQueue" enableLogging:NO];
        mainTaskQueue.enableLogging = YES;
        [mainTaskQueue start];
        console             = [[UMLogConsole alloc] init];
        mainLogHandler      = [[UMLogHandler alloc] init];
        [mainLogHandler addLogDestination:console];
        logFeed = [[UMLogFeed alloc]initWithHandler:mainLogHandler section:@"core"];
        logFeed.name = @"core";
        time_t now;
        time(&now);
        unsigned int speed = (unsigned int) now;
        srandom(speed);

    }
    return self;
}


/* Http admin server for sms router is started. Do not start server if one is not configured.*/
- (void)setupWebserver
{
    /* Admin HTTP */
    if (webPort > 0)
    {
        httpServer = [[UMHTTPServer alloc] initWithPort:webPort];
        httpServer.name = @"httpServer";
        httpServer.httpGetPostDelegate = self;
        [httpServer start];
    }
}


- (void)httpGetPost:(UMHTTPRequest *)req
{
    if([req.method isEqualToString: @"GET"])
    {
        [req extractGetParams];
    }
    if([req.url.relativePath isEqualToString:@"/"])
    {
        
        NSString *failovername = req.params[@"failover"];
        if([failovername length]>0)
        {
            [listener failover:failovername];
        }
        NSString *s = [self htmlStatus];
        [req setResponseHtmlString:s];
        req.responseCode = HTTP_RESPONSE_CODE_OK;
    }
    else
    {
        [req setResponseHtmlString:@"404, page not found"];
        req.responseCode = HTTP_RESPONSE_CODE_NOT_FOUND;
    }
}

- (void)readConfig:(NSString *)filename
{
    NSLog(@"Reading config from %@",filename);
    config = [[UMConfig alloc]initWithFileName:filename];
    [config allowSingleGroup:@"core"];
    [config allowMultiGroup:@"resource"];
    [config read];
    
    NSDictionary *coreConfig = [config getSingleGroup:@"core"];
    localAddress     = [UMSocket unifyIP:[coreConfig[@"local-address"]stringValue]];
    remoteAddress    = [UMSocket unifyIP:[coreConfig[@"remote-address"]stringValue]];
    sharedAddress    = [UMSocket unifyIP:[coreConfig[@"shared-address"]stringValue]];
    port             = [coreConfig[@"port"]intValue];
    webPort          = [coreConfig[@"http-port"]intValue];
    logDirectory     = [coreConfig[@"log-dir"]  stringValue];
    heartbeat        = [coreConfig[@"heartbeat"] doubleValue];
    timeout          = [coreConfig[@"timeout"] doubleValue];

    if(heartbeat <= 0.01)
    {
        heartbeat=2.0;
    }
    if(timeout < (3*heartbeat))
    {
        timeout=3*heartbeat;
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSDictionary *notif = [aNotification object];
    NSString *configFileName = notif[@"fileName"];
    if (!configFileName)
    {
        configFileName = @"/etc/schrittmacher/schrittmacher.conf";
    }
    
    [self readConfig:configFileName];

    NSDictionary *coreConfig = [config getSingleGroup:@"core"];
    [self addLogFromConfigGroup:coreConfig
                      toHandler:mainLogHandler
                         logdir:logDirectory];

    [self setupWebserver];
    [self startupListener];
    updateTimer     = [NSTimer timerWithTimeInterval:2.0
                                              target:self
                                            selector:@selector(heartbeatAction)
                                            userInfo:@""
                                             repeats:YES];
    pollTimer       = [NSTimer timerWithTimeInterval:0.05
                                               target:self
                                             selector:@selector(pollAction)
                                             userInfo:@""
                                              repeats:YES];

    checkIfUpTimer  = [NSTimer timerWithTimeInterval:(double)0.5
                                                  target:self
                                                selector:@selector(checkIfUp)
                                                userInfo:@""
                                                 repeats:YES];

    NSRunLoop *crl  = [NSRunLoop currentRunLoop];
    [crl addTimer:updateTimer forMode:NSDefaultRunLoopMode];
    [crl addTimer:pollTimer forMode:NSDefaultRunLoopMode];
    [crl addTimer:checkIfUpTimer forMode:NSDefaultRunLoopMode];
}

- (void)heartbeatAction
{
    [listener heartbeat];
}

-(void)pollAction
{
    [listener checkForPackets];
    [listener checkForTimeouts];
}

- (NSString *)htmlStatus
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"<H1>Status</H1>\n<p>%@</p>\n", @"running"];
    [s appendFormat:@"<table border=1>"];
    [s appendFormat:@"<tr>"];
    [s appendFormat:@"<th>Resource</th>"];
    [s appendFormat:@"<th>Status</th>"];
    [s appendFormat:@"<th>LastRx</th>"];
    [s appendFormat:@"<th>LastLocalRx</th>"];
    [s appendFormat:@"<th>Action</th>"];
    [s appendFormat:@"</tr>"];

    NSDictionary *states = [listener status];
    NSArray *keys = [states allKeys];
    
    keys = [keys sortedArrayUsingComparator: ^(id a, id b) {
        return [a compare:b];
    }];
    
    for(NSString *key in keys)
    {
        NSDictionary *dict = states[key];
        NSString *failover;
    
        if([dict[@"current-state"] isEqualToString:@"Hot"])
        {
            failover = [NSString stringWithFormat:@"<a href=/?failover=%@>failover</a>", [key urlencode] ];
        }
        else
        {
            failover=@"&nbsp;";
        }
        
        [s appendFormat:@"<tr>"];
        [s appendFormat:@"<td>%@</td>",dict[@"resource-id"]];
        [s appendFormat:@"<td>%@</td>",dict[@"current-state"]];
        [s appendFormat:@"<td>%@</td>",dict[@"lastRx"]];
        [s appendFormat:@"<td>%@</td>",dict[@"lastLocalRx"]];
        [s appendFormat:@"<td>%@</td>",failover];
        [s appendFormat:@"</tr>"];
    }
    [s appendFormat:@"</table>"];
    return s;
}


- (void)startupListener
{
    listener = [[Listener alloc]init];

    int addrType = 4;
    NSString *unifiedLocalAddress =  [UMSocket unifyIP:localAddress];
    [UMSocket deunifyIp:unifiedLocalAddress type:&addrType];
    
    listener.localHost =[[UMHost alloc]initWithLocalhostAddresses:@[unifiedLocalAddress]];
    listener.port = port;
    listener.addressType= addrType;
    NSArray *configs = [config getMultiGroups:@"resource"];
    for(NSDictionary *daemonConfig in configs)
    {
        NSString *startAction      = [daemonConfig[@"start-action"] stringValue];
        NSString *stopAction       = [daemonConfig[@"stop-action"] stringValue];
        NSString *resourceName     = [daemonConfig[@"name"] stringValue];
        int priority               = [daemonConfig[@"priority"] intValue];
        NSString *pidFile          = [daemonConfig[@"pid-file"] stringValue];
        NSString *activate         = [daemonConfig[@"interface-activate"] stringValue];
        NSString *deactivate       = [daemonConfig[@"interface-deactivate"] stringValue];

        double  startupDelay       = [daemonConfig[@"startup-delay"] doubleValue];
        double  intervallDelay     = [daemonConfig[@"heartbeat-intervall"] doubleValue];

        if(startupDelay < 1)
        {
            startupDelay = 20;
        }
        if(intervallDelay < 0.1)
        {
            intervallDelay = 5;
        }
        Daemon *d = [[Daemon alloc]init];
        d.localAddress = localAddress;
        d.remoteAddress =remoteAddress;
        d.sharedAddress = sharedAddress;
        d.remotePort = port;
        d.resourceId = resourceName;
        d.startAction = startAction;
        d.stopAction = stopAction;
        d.localPriority = priority;
        d.activateInterfaceCommand = activate;
        d.deactivateInterfaceCommand = deactivate;
        d.startupDelay = startupDelay;
        d.intervallDelay = intervallDelay;
        d.pidFile = pidFile;
        [listener attachDaemon:d];
    }
    [listener start];
}


- (void)checkIfUp
{
    [listener checkIfUp];
}

@end
