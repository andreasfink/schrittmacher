//
//  AppDelegate.m
//  schrittmacher
//
//  Created by Andreas Fink on 20/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
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
        self.logFeed = [[UMLogFeed alloc]initWithHandler:mainLogHandler section:@"core"];
        self.logFeed.name = @"core";
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
        NSString *takeovername = req.params[@"takeover"];
        if([takeovername length]>0)
        {
            [listener takeover:takeovername];
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
    [self.logFeed debugText:[NSString stringWithFormat:@"Reading config from %@",filename]];
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
    @autoreleasepool
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
}

- (void)heartbeatAction
{
    @autoreleasepool
    {
        [listener heartbeat];
    }
}

-(void)pollAction
{
    @autoreleasepool
    {
        [listener checkForPackets];
        [listener checkForTimeouts];
    }
}

- (NSString *)htmlStatus
{
    @autoreleasepool
    {

        NSMutableString *s = [[NSMutableString alloc]init];
        [s appendFormat:@"<H1>Status</H1>\n"];
        [s appendFormat:@"<table border=1>\n"];
        [s appendFormat:@"<tr>\n"];
        [s appendFormat:@"<th rowspan=2>Resource</th>\n"];
        [s appendFormat:@"<th rowspan=2>Remote Status</th>\n"];
        [s appendFormat:@"<th rowspan=2>Local Status</th>\n"];
        [s appendFormat:@"<th colspan=2>Heartbeat</th>\n"];
        [s appendFormat:@"<th colspan=2>Failure</th>\n"];
        [s appendFormat:@"<th rowspan=2>Action</th>\n"];
        [s appendFormat:@"</tr>"];

        [s appendFormat:@"<tr>\n"];
        [s appendFormat:@"<th>Remote</th>\n"];
        [s appendFormat:@"<th>Local</th>\n"];
        [s appendFormat:@"<th>Remote</th>\n"];
        [s appendFormat:@"<th>Local</th>\n"];
        [s appendFormat:@"</tr>"];

        NSDictionary *states = [listener status];
        NSArray *keys = [states allKeys];

        keys = [keys sortedArrayUsingComparator: ^(id a, id b) {
            return [a compare:b];
        }];

        for(NSString *key in keys)
        {
            NSDictionary *dict = states[key];
            NSString *action;

            if([dict[@"local-state"] isEqualToString:@"hot"])
            {
                action = [NSString stringWithFormat:@"<a href=/?failover=%@>failover</a>", [key urlencode] ];
            }
            else if([dict[@"local-state"] isEqualToString:@"standby"])
            {
                action = [NSString stringWithFormat:@"<a href=/?takeover=%@>takeover</a>", [key urlencode] ];
            }

            [s appendFormat:@"<tr>"];
            [s appendFormat:@"<td>%@</td>",dict[@"resource-id"]];
            [s appendFormat:@"<td>%@</td>",dict[@"remote-state"]];
            [s appendFormat:@"<td>%@</td>",dict[@"local-state"]];
            [s appendFormat:@"<td>%@</td>",dict[@"lastRemoteRx"]];
            [s appendFormat:@"<td>%@</td>",dict[@"lastLocalRx"]];
            [s appendFormat:@"<td>%@</td>",dict[@"remoteIsFailed"]];
            [s appendFormat:@"<td>%@</td>",dict[@"localIsFailed"]];
            [s appendFormat:@"<td>%@</td>",action];
            [s appendFormat:@"</tr>"];
        }
        [s appendFormat:@"</table>"];
        return s;
    }
}


- (void)startupListener
{
    @autoreleasepool
    {

        listener = [[Listener alloc]init];

        int addrType = 4;
        NSString *unifiedLocalAddress =  [UMSocket unifyIP:localAddress];
        [UMSocket deunifyIp:unifiedLocalAddress type:&addrType];
        listener.localHostPublic =[[UMHost alloc]initWithLocalhostAddresses:@[unifiedLocalAddress ? unifiedLocalAddress : @"0.0.0.0"]];
        listener.localHostPrivate=[[UMHost alloc]initWithLocalhostAddresses:@[@"127.0.0.1"]];
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
            double  intervallDelay     = [daemonConfig[@"heartbeat-intervall"] doubleValue];

            if(intervallDelay < 2)
            {
                intervallDelay = 2;
            }
            Daemon *d = [[Daemon alloc]init];
            d.logFeed = [[UMLogFeed alloc]initWithHandler:mainLogHandler section:resourceName];
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
            d.intervallDelay = intervallDelay;
            d.pidFile = pidFile;
            [listener attachDaemon:d];
        }
        [listener start];
    }
}

- (void)checkIfUp
{
    @autoreleasepool
    {
        [listener checkIfUp];
    }
}

@end
