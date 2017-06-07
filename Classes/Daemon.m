//
//  Daemon.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "Daemon.h"
#import "DaemonState_all.h"
#import "Listener.h"
#import <stdint.h>

DaemonRandomValue GetDaemonRandomValue(void)
{
    return (DaemonRandomValue)arc4random();
}

@implementation Daemon
@synthesize currentState;
@synthesize localPriority;
@synthesize resourceId;
@synthesize listener;
@synthesize remoteAddress;
@synthesize netmask;
@synthesize remotePort;
@synthesize timeout;
@synthesize lastRx;
@synthesize lastLocalRx;
@synthesize startAction;
@synthesize stopAction;
@synthesize localAddress;
@synthesize sharedAddress;
@synthesize pidFile;
@synthesize activateInterfaceCommand;
@synthesize deactivateInterfaceCommand;
@synthesize intervallDelay;

- (Daemon *)init
{
    self = [super init];
    if(self)
    {
        lastLocalRx = [NSDate date];
    }
    return self;
}

- (void)actionStart
{
    if(timeout<=0)
    {
        timeout=6.0;
    }
    DaemonState_Unknown *startState = [[DaemonState_Unknown alloc]initWithDaemon:self];
    currentState = [startState eventStart];
}

- (void)sendStatus:(NSString *)status
{
    return [self sendStatus:status withRandomValue:0];
}

- (void)sendStatus:(NSString *)status withRandomValue:(DaemonRandomValue)r
{
    NSDictionary *dict = @{ @"resource" : resourceId,
                            @"status"   : status,
                            @"priority" : @(localPriority),
                            @"random"   : @(r)};
    
    NSString *msg = [dict jsonString];
    [logFeed debugText:[NSString stringWithFormat:@"TX %@->%@: %@",localAddress,remoteAddress,dict]];
    [listener sendString:msg toAddress:remoteAddress toPort:remotePort];
}


- (void)actionSendUnknown
{
    _randVal = GetDaemonRandomValue();
    [self sendStatus:MESSAGE_UNKNOWN withRandomValue:_randVal];
}

- (void)actionSendFailed
{
    [self sendStatus:MESSAGE_FAILED];
}

- (void)actionSendHot
{
    [self sendStatus:MESSAGE_HOT];
}

- (void)actionSendStandby
{
    [self sendStatus:MESSAGE_STANDBY];
}

- (void)actionSendTakeoverRequest
{
    _randVal = GetDaemonRandomValue();
    [self sendStatus:MESSAGE_TAKEOVER_REQUEST withRandomValue:_randVal];
}

- (void)actionSendTakeoverRequestForced
{
    _randVal = INT_MAX;
    [self sendStatus:MESSAGE_TAKEOVER_REQUEST withRandomValue:_randVal];
}

- (void)actionSendTakeoverReject
{
    [self sendStatus:MESSAGE_TAKEOVER_REJECT];
}

- (void)actionSendTakeoverConfirm
{
    [self sendStatus:MESSAGE_TAKEOVER_CONF];
}

#define DEBUGLOG(state,event) \
{ \
    NSString *s = [NSString stringWithFormat:@"State:%@ event:%@",state.name,event]; \
    [logFeed debugText:s]; \
}

- (void)eventReceived:(NSString *)event
                 dict:(NSDictionary *)dict;
{
    NSString *oldstate = [currentState name];

    /*local message */
    if ([event isEqualToString:MESSAGE_LOCAL_HOT])
    {
        self.localIsFailed=NO;
        lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localHotIndication");
        currentState = [currentState eventStatusLocalHot:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_STANDBY])
    {
        self.localIsFailed=NO;
        lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localStandbyIndication");
        currentState = [currentState eventStatusLocalStandby:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_UNKNOWN])
    {
        self.localIsFailed=NO;
        lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localUnknownIndication");
        currentState = [currentState eventStatusLocalUnknown:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_FAIL])
    {
        self.localIsFailed=YES;
        lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localFailureIndication");
        currentState = [currentState eventStatusLocalFailure:dict];
    }
    
    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_UNKNOWN])
    {
        self.remoteIsFailed=NO;
        lastRx = [NSDate date];
        DEBUGLOG(currentState,@"eventUnknown");
        currentState = [currentState eventStatusRemoteUnknown:dict];
    }

    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_FAILED])
    {
        self.remoteIsFailed=YES;
        lastRx = [NSDate date];
        DEBUGLOG(currentState,@"eventRemoteFailed");
        currentState = [currentState eventStatusRemoteFailure:dict];
    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_REQUEST])
    {
        self.remoteIsFailed=NO;
        lastRx = [NSDate date];
        DEBUGLOG(currentState,@"eventTakeoverRequest");
        currentState = [currentState eventTakeoverRequest:dict];
    }
    else if ([event isEqualToString:MESSAGE_TAKEOVER_REJECT])
    {
        lastRx = [NSDate date];
        DEBUGLOG(currentState,@"eventTakeoverReject");
        currentState = [currentState eventTakeoverReject:dict];
    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_CONF])
    {
        lastRx = [NSDate date];
        DEBUGLOG(currentState,@"eventTakeoverConf");
        currentState = [currentState eventTakeoverConf:dict];
    }
    else if ([event isEqualToString:MESSAGE_STANDBY])
    {
        self.remoteIsFailed=NO;
        lastRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusStandby");
        currentState = [currentState eventStatusRemoteStandby:dict];
    }
    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_HOT])
    {
        self.remoteIsFailed=NO;
        lastRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusHot");
        currentState = [currentState eventStatusRemoteHot:dict];
    }
    
    NSAssert(currentState,@"State is now null");
    NSString *newstate = [currentState name];
    if(![oldstate isEqualToString:newstate])
    {
        NSString *s = [NSString stringWithFormat:@"State Change %@->%@",oldstate,newstate];
        [logFeed debugText:s];
    }
}

- (void)eventTimer
{
    currentState = [currentState eventTimer];
}

- (void)eventForceFailover
{
    currentState = [currentState eventStatusLocalFailure:@{}];
}

- (void)eventForceTakeover
{
    currentState = [currentState eventStatusLocalFailure:@{}];
}

- (void)checkForTimeouts
{
    NSDate *now = [NSDate date];
    NSTimeInterval delay = [now timeIntervalSinceDate:lastRx];
    if(delay > timeout)
    {
        currentState = [currentState eventTimeout];
    }
}

- (int)goToHot /* returns 0 on success  */
{
    if(!iAmHot)
    {
        int r = [self fireUp];
        if(r==0)
        {
            iAmHot = YES;
            return GOTO_HOT_SUCCESS;
        }
        else
        {
            iAmHot = NO;
            return GOTO_HOT_FAILED;
        }
    }
    else
    {
        return GOTO_HOT_ALREADY_HOT;
    }
}

- (int)goToStandby /* returns 0 on success */
{
    int r1 = [self callStopAction];
    int r2 = [self callDeactivateInterface];
    if(r1!=0)
    {
        return r1;
    }
    return r2;
}

#define     SETENV(a,b)   if(b!=NULL) { setenv(a,b.UTF8String,1);  } else { unsetenv(a); }


- (void)setEnvVars
{
    NSString *heartbeatIntervall = [NSString stringWithFormat:@"%lf",intervallDelay];
    SETENV("NETMASK",  netmask);
    SETENV("LOCAL_ADDRESS",  localAddress);
    SETENV("REMOTE_ADDRESS", remoteAddress);
    SETENV("SHARED_ADDRESS", sharedAddress);
    SETENV("RESOURCE_NAME", resourceId);
    SETENV("PID_FILE", pidFile);
    SETENV("HEARTBEAT_INTERVAL", heartbeatIntervall);
}


- (void)unsetEnvVars
{
    unsetenv("NETMASK");
    unsetenv("LOCAL_ADDRESS");
    unsetenv("REMOTE_ADDRESS");
    unsetenv("SHARED_ADDRESS");
    unsetenv("RESOURCE_NAME");
    unsetenv("PID_FILE");
    unsetenv("ACTION");
    unsetenv("HEARTBEAT_INTERVAL");
}

- (int)executeScript:(NSString *)command
{
    if(command.length==0) /* empty script is always a success */
    {
        return 0;
    }
    const char *cmd = command.UTF8String;
    [logFeed debugText:[NSString stringWithFormat:@" Executing: %s",cmd]];
    return system(cmd);
}


- (int)callActivateInterface
{
    if(self.interfaceState == DaemonInterfaceState_Up)
    {
        return 0;
    }

    if(activateInterfaceCommand.length == 0)
    {
        return 0;
    }
    [self setEnvVars];
    setenv("ACTION", "activate", 1);
    int r = [self executeScript:activateInterfaceCommand];
    [self unsetEnvVars];
    if(r==0)
    {
        activatedAt = [NSDate date];
        self.interfaceState = DaemonInterfaceState_Up;
    }
    else
    {
        self.interfaceState = DaemonInterfaceState_Unknown;
    }
    return r;

}


- (int) callDeactivateInterface
{
    if(self.interfaceState == DaemonInterfaceState_Down)
    {
        return 0;
    }
    
    [self setEnvVars];
    setenv("ACTION", "deactivate", 1);
    int r = [self executeScript:deactivateInterfaceCommand];
    [self unsetEnvVars];
    if(r==0)
    {
        deactivatedAt = [NSDate date];
        self.interfaceState = DaemonInterfaceState_Down;

    }
    else
    {
        self.interfaceState = DaemonInterfaceState_Unknown;
    }
    return r;
    
}

- (int)callStartAction
{
    self.localStartActionRequested = YES;
    if(startAction.length == 0)
    {
        return 0;
    }
    [self setEnvVars];
    setenv("ACTION", "start", 1);
    int r = [self executeScript:startAction];
    [self unsetEnvVars];
    if(r==0)
    {
        startedAt = [NSDate date];
    }
    return r;
}

-(int)callStopAction
{
    self.localStopActionRequested = YES;
    
    if(stopAction.length == 0)
    {
        return 0;
    }
    [self setEnvVars];
    setenv("ACTION", "stop", 1);
    const char *cmd = stopAction.UTF8String;
    [logFeed debugText:[NSString stringWithFormat:@" Executing: %s",cmd]];
    int r = system(cmd);
    [self unsetEnvVars];
    if(r==0)
    {
        stoppedAt = [NSDate date];
    }
    return r;
}



- (int)fireUp
{
    int r1 = [self callActivateInterface];
    int r2 = [self callStartAction];
    if(r1!=0)
    {
        return r1;
    }
    return r2;
}

- (NSDictionary *)status
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    @synchronized(self)
    {
        dict[@"resource-id"]= resourceId;
        dict[@"current-state"]=[currentState name];
        dict[@"lastRx"] = lastRx ? [lastRx stringValue] : @"-";
        dict[@"lastLocalRx"] = lastLocalRx ? [lastLocalRx stringValue] : @"-";
        dict[@"remoteAddress"] = remoteAddress;
        dict[@"localAddress"] = localAddress;
        dict[@"sharedAddress"] = sharedAddress;
        dict[@"startAction"] = startAction;
        dict[@"stopAction"] = stopAction;
        dict[@"activateInterfaceCommand"] = activateInterfaceCommand;
        dict[@"deactivateInterfaceCommand"] = deactivateInterfaceCommand;
        dict[@"localPriority"] = [NSString stringWithFormat:@"%d",(int)localPriority];
        dict[@"lastChecked"] = [lastChecked stringValue];
        dict[@"startedAt"] = startedAt ? [startedAt stringValue] : @"never";
        dict[@"stoppedAt"] = stoppedAt ? [stoppedAt stringValue] : @"never";
        dict[@"activatedAt"] = activatedAt ? [activatedAt stringValue] : @"never";
        dict[@"dectivatedAt"] = deactivatedAt ? [deactivatedAt stringValue] : @"never";
        dict[@"remoteIsFailed"] = _remoteIsFailed ? @"YES" : @"NO";
        dict[@"localIsFailed"] = _localIsFailed ? @"YES" : @"NO";
    }
    return dict;
}


- (void)checkIfUp
{
    /* we check if we have received the heartbeat from the local instance */
    if(lastLocalRx == NULL)
    {
        lastLocalRx = [NSDate date];
    }
    lastChecked = [NSDate date];
    NSTimeInterval delay = [lastChecked timeIntervalSinceDate:lastLocalRx];
    if(delay > intervallDelay)
    {
        DEBUGLOG(currentState,@"eventStatusLocalFailure");
        currentState = [currentState eventStatusLocalFailure:@{}];
    }
}

@end
