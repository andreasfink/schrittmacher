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
#import "SchrittmacherMetrics.h"

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
        _mainTaskQueue =[[UMTaskQueue alloc]initWithNumberOfThreads:threadCount
                                                               name:@"mainTaskQueue"
                                                      enableLogging:NO];
        _mainTaskQueue.enableLogging = YES;
        [_mainTaskQueue start];
        _console             = [[UMLogConsole alloc] init];
        _mainLogHandler      = [[UMLogHandler alloc] init];
        [_mainLogHandler addLogDestination:_console];
        self.logFeed = [[UMLogFeed alloc]initWithHandler:_mainLogHandler section:@"core"];
        self.logFeed.name = @"schrittmacher";
        _logLevel = UMLOG_MAJOR;
        time_t now;
        time(&now);
        unsigned int speed = (unsigned int) now;
        srandom(speed);
        _prometheus = [[UMPrometheus alloc]init];
        UMPrometheusMetricUptime *uptimeMetric = [[UMPrometheusMetricUptime alloc]init];
        [_prometheus addMetric:uptimeMetric];

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
    else if ([req.url.relativePath isEqualToString:@"/metrics"])
    {
        NSString *html = [_prometheus prometheusOutput];
        NSData *d = [html dataUsingEncoding:NSUTF8StringEncoding];
        [req setResponseHeader:@"Content-Type" withValue:@"text/plain; version=0.0.4"];
        [req setResponseData:d];
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
    if(coreConfig[@"port"])
    {
        _port             = [coreConfig[@"port"]intValue];
    }
    if(coreConfig[@"public-port"])
    {
        _port             = [coreConfig[@"public-port"]intValue];
    }
    _webPort          = [coreConfig[@"http-port"]intValue];
    _logDirectory     = [coreConfig[@"log-dir"]  stringValue];
    
    NSString *s =   coreConfig[@"heartbeat"];
    if((s == NULL) || (s.length ==0))
    {
        _heartbeat = 2.0;
    }
    else
    {
        _heartbeat = [s doubleValue];
    }
    if(_heartbeat <= 0.01)
    {
        _heartbeat = 2.0;
    }
    if(_heartbeat > 20)
    {
        _heartbeat = 20;
    }

    s = coreConfig[@"timeout"];
    if((s == NULL) || (s.length ==0))
    {
        _timeout = 6.0;
    }
    else
    {
        _timeout          = [coreConfig[@"timeout"] doubleValue];
    }

    if(_timeout < (3.0 *_heartbeat))
    {
        _timeout = 3.0 * _heartbeat;
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
        [s appendFormat:@"<th>Resource</th>\n"];
        [s appendFormat:@"<th>Status</th>\n"];
        [s appendFormat:@"<th>Last Local Message</th>\n"];
        [s appendFormat:@"<th>Last Remote Message</th>\n"];
        [s appendFormat:@"<th>Action</th>\n"];
        [s appendFormat:@"</tr>"];

        NSDictionary *states = [_listener status];
        NSArray *keys = [states allKeys];

        keys = [keys sortedArrayUsingComparator: ^(id a, id b)
        {
            return [a compare:b];
        }];

        for(NSString *key in keys)
        {
            NSDictionary *dict = states[key];
            NSString *action=@"";

            if(   ([dict[@"state"] isEqualTo:@"Hot"])
               || ([dict[@"state"] isEqualTo:@"hot"]))
            {
                action = [NSString stringWithFormat:@"<a href=/?failover=%@>failover</a>", [key urlencode] ];
            }
            else if(([dict[@"state"] isEqualTo:@"Standby"])
                 || ([dict[@"state"] isEqualTo:@"standby"]))
            {
                action = [NSString stringWithFormat:@"<a href=/?takeover=%@>takeover</a>", [key urlencode] ];
            }

            [s appendFormat:@"<tr>"];
            [s appendFormat:@"<td>%@</td>",dict[@"resource-id"]];
            [s appendFormat:@"<td>%@</td>",dict[@"state"]];
            [s appendFormat:@"<td>%@<br>%@<br>%@</td>",dict[@"last-local-message"],dict[@"last-local-message-received"],dict[@"last-local-reason"]];
            [s appendFormat:@"<td>%@<br>%@<br>%@</td>",dict[@"last-remote-message"],dict[@"last-remote-message-received"],dict[@"last-remote-reason"]];
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
        _listener.logFeed = self.logFeed;
        _listener.logHandler = _mainLogHandler;
        _listener.logLevel = self.logLevel;

        int addrType = 4;
        NSArray *a;
        if(_localAddress)
        {
            NSString *unifiedLocalAddress =  [UMSocket unifyIP:_localAddress];
            [UMSocket deunifyIp:unifiedLocalAddress type:&addrType];
            a = @[unifiedLocalAddress,@"127.0.0.1",@"::1"];
        }
        else
        {
            a = @[@"0.0.0.0"];
        }
        _listener.localAddress = _localAddress;
        _listener.port = _port;
        _listener.addressType= addrType;
        
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
            d.remotePort = _port;
            d.resourceId = resourceName;
            d.startAction = startAction;
            d.stopAction = stopAction;
            d.localPriority = priority;
            d.activateInterfaceCommand = activate;
            d.deactivateInterfaceCommand = deactivate;
            d.intervallDelay = intervallDelay;
            d.pidFile = pidFile;
            d.pid = 0;
            d.logLevel = _logLevel;
            d.prometheusMetrics = [[SchrittmacherMetrics alloc]initWithPrometheus:_prometheus];
            [d.prometheusMetrics setSubname1:@"resource-name" value:resourceName];
            [d.prometheusMetrics registerMetrics];
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
                                                          name:@"check-if-up-timer"
                                                       repeats:YES];
            [_listener attachDaemon:d];
            [d.heartbeatTimer start];
            [d.checkIfUpTimer start];
        }
        [_listener start];
    }
}


@end
