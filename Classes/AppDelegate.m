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
        time(&_g_startup_time);
        int threadCount = ulib_cpu_count();
        _mainTaskQueue =[[UMTaskQueue alloc]initWithNumberOfThreads:threadCount name:@"mainTaskQueue" enableLogging:NO];
        _mainTaskQueue.enableLogging = YES;
        [_mainTaskQueue start];
        _console             = [[UMLogConsole alloc] init];
        _mainLogHandler      = [[UMLogHandler alloc] init];
        [_mainLogHandler addLogDestination:_console];
        self.logFeed = [[UMLogFeed alloc]initWithHandler:_mainLogHandler section:@"core"];
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
    if (_webPort > 0)
    {
        _httpServer = [[UMHTTPServer alloc] initWithPort:_webPort];
        _httpServer.name = @"httpServer";
        _httpServer.httpGetPostDelegate = self;
        [_httpServer start];
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
            [_listener failover:failovername];
        }
        NSString *takeovername = req.params[@"takeover"];
        if([takeovername length]>0)
        {
            [_listener takeover:takeovername];
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
    _config = [[UMConfig alloc]initWithFileName:filename];
    [_config allowSingleGroup:@"core"];
    [_config allowMultiGroup:@"resource"];
    [_config read];
    
    NSDictionary *coreConfig = [_config getSingleGroup:@"core"];
    _localAddress     = [UMSocket unifyIP:[coreConfig[@"local-address"]stringValue]];
    _remoteAddress    = [UMSocket unifyIP:[coreConfig[@"remote-address"]stringValue]];
    _sharedAddress    = [UMSocket unifyIP:[coreConfig[@"shared-address"]stringValue]];
    _publicPort      = [coreConfig[@"public-port"]intValue];
    _privatePort     = [coreConfig[@"private-port"]intValue];
    _webPort          = [coreConfig[@"http-port"]intValue];
    _logDirectory     = [coreConfig[@"log-dir"]  stringValue];
    _heartbeat        = [coreConfig[@"heartbeat"] doubleValue];
    _timeout          = [coreConfig[@"timeout"] doubleValue];

    if(_heartbeat <= 0.01)
    {
        _heartbeat=2.0;
    }
    if(_timeout < (3*_heartbeat))
    {
        _timeout=3*_heartbeat;
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

        NSDictionary *coreConfig = [_config getSingleGroup:@"core"];
        [self addLogFromConfigGroup:coreConfig
                          toHandler:_mainLogHandler
                             logdir:_logDirectory];

        [self setupWebserver];
        [self startupListener];
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

        NSDictionary *states = [_listener status];
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

        _listener = [[Listener alloc]init];

        int addrType = 4;
        NSString *unifiedLocalAddress =  [UMSocket unifyIP:_localAddress];
        [UMSocket deunifyIp:unifiedLocalAddress type:&addrType];
        _listener.localHostPublic =[[UMHost alloc]initWithLocalhostAddresses:@[unifiedLocalAddress ? unifiedLocalAddress : @"0.0.0.0"]];
        _listener.localHostPrivate=[[UMHost alloc]initWithLocalhostAddresses:@[@"127.0.0.1"]];
        _listener.publicPort = _publicPort;
        _listener.privatePort = _privatePort;
        _listener.addressType= addrType;
        
        _listener.pollTimer =  [[UMTimer alloc]initWithTarget:_listener
                                            selector:@selector(pollAction)
                                              object:NULL
                                             seconds:0.050
                                                name:@"poll-timer"
                                             repeats:YES];
        NSArray *configs = [_config getMultiGroups:@"resource"];
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

            if(intervallDelay < 2.0)
            {
                intervallDelay = 2.0;
            }
            Daemon *d = [[Daemon alloc]init];
            d.logFeed = [[UMLogFeed alloc]initWithHandler:_mainLogHandler section:resourceName];
            d.localAddress = _localAddress;
            d.remoteAddress = _remoteAddress;
            d.sharedAddress = _sharedAddress;
            d.remotePort = _publicPort;
            d.resourceId = resourceName;
            d.startAction = startAction;
            d.stopAction = stopAction;
            d.localPriority = priority;
            d.activateInterfaceCommand = activate;
            d.deactivateInterfaceCommand = deactivate;
            d.intervallDelay = intervallDelay;
            d.pidFile = pidFile;
            d.heartbeatTimer =  [[UMTimer alloc]initWithTarget:d
                                                      selector:@selector(eventHeartbeat)
                                                        object:NULL
                                                       seconds:d.intervallDelay
                                                          name:@"heartbeat-timer"
                                                       repeats:YES];
            
            d.checkIfUpTimer =  [[UMTimer alloc]initWithTarget:d
                                                      selector:@selector(checkIfUp)
                                                        object:NULL
                                                       seconds:d.intervallDelay
                                                          name:@"heartbeat-timer"
                                                       repeats:YES];

            [_listener attachDaemon:d];
            [d.heartbeatTimer start];
            [d.checkIfUpTimer start];
        }
        [_listener start];
    }
}


@end
