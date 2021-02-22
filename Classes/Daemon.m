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
    return (DaemonRandomValue)[UMUtil random:(UINT_MAX-1)];
}

@implementation Daemon
@synthesize currentState;
@synthesize localPriority;
@synthesize resourceId;
@synthesize listener;
@synthesize remoteAddress;
@synthesize netmask;
@synthesize remotePort;
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
        _lastLocalRx = [NSDate date];
    }
    return self;
}

- (void)actionStart
{
    if(_timeout<=0)
    {
        _timeout=6.0;
    }
    if(_goingHotTimeout <=0)
    {
        _goingHotTimeout = 20.0;
    }
    if(_goingStandbyTimeout <=0)
    {
        _goingStandbyTimeout = 6;
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
    [self.logFeed debugText:[NSString stringWithFormat:@"TX %@->%@: %@",localAddress,remoteAddress,dict]];
    [listener sendString:msg toAddress:remoteAddress toPort:remotePort];
}

- (void)actionSendUnknown
{
    _randVal = GetDaemonRandomValue();
    _lastHotSent = NULL;
    _lastStandbySent = NULL;
    [self sendStatus:MESSAGE_UNKNOWN withRandomValue:_randVal];
}

- (void)actionSendFailed
{
    [self sendStatus:MESSAGE_FAILED];
    _lastHotSent = NULL;
    _lastStandbySent = NULL;
}

- (void)actionSendFailover
{
    [self sendStatus:MESSAGE_FAILOVER];
    _lastHotSent = NULL;
    _lastStandbySent = NULL;
}

- (void)actionSendHot
{
    [self sendStatus:MESSAGE_HOT];
    _lastHotSent = [NSDate date];
    _lastStandbySent = NULL;
}

- (void)actionSendStandby
{
    [self sendStatus:MESSAGE_STANDBY];
    _lastHotSent = NULL;
    _lastStandbySent = [NSDate date];
}

- (void)actionSendTakeoverRequest
{
    _randVal = GetDaemonRandomValue();
    [self sendStatus:MESSAGE_TAKEOVER_REQUEST withRandomValue:_randVal];
}

- (void)actionSendTakeoverRequestForced
{
    _randVal = GetDaemonRandomValue();
    [self sendStatus:MESSAGE_TAKEOVER_REQUEST withRandomValue:UINT_MAX];
}

- (void)actionSendTakeoverReject
{
    [self sendStatus:MESSAGE_TAKEOVER_REJECT];
}

- (void)actionSendTakeoverConfirm
{
    [self sendStatus:MESSAGE_TAKEOVER_CONF];
}


- (void)actionSendTransitingToHot
{
    [self sendStatus:MESSAGE_TRANSITING_TO_HOT];
}


- (void)actionSendTransitingToStandby
{
    [self sendStatus:MESSAGE_TRANSITING_TO_STANDBY];
}

#define DEBUGLOG(state,event) \
{ \
    NSString *s = [NSString stringWithFormat:@"State:%@ event:%@",state.name,event]; \
    [self.logFeed debugText:s]; \
}

- (void)eventReceived:(NSString *)event
                 dict:(NSDictionary *)dict;
{
    NSString *oldstate = [currentState name];

    
    /*
     * LOCAL MESSAGES
     */

    if ([event isEqualToString:MESSAGE_LOCAL_HOT])
    {
        _lastLocalState=@"hot";
        self.localIsFailed=NO;
        _lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localHotIndication");
        currentState = [currentState eventStatusLocalHot:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_STANDBY])
    {
        _lastLocalState=@"standby";
        self.localIsFailed=NO;
        _lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localStandbyIndication");
        currentState = [currentState eventStatusLocalStandby:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_UNKNOWN])
    {
        _lastLocalState=@"unknown";
        self.localIsFailed=NO;
        _lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localUnknownIndication");
        currentState = [currentState eventStatusLocalUnknown:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_FAIL])
    {
        _lastLocalState=@"fail";
        self.localIsFailed=YES;
        _lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localFailureIndication");
        currentState = [currentState eventStatusLocalFailure:dict];
    }
    
    else if ([event isEqualToString:MESSAGE_LOCAL_TRANSITING_TO_HOT])
    {
        _lastLocalState=@"transiting-to-hot";
        self.localIsFailed=NO;
        _lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localTransitingToHot");
        currentState = [currentState eventStatusLocalTransitingToHot:dict];
    }

    else if ([event isEqualToString:MESSAGE_LOCAL_TRANSITING_TO_STANDBY])
    {
        _lastLocalState=@"transiting-to-standby";
        self.localIsFailed=NO;
        _lastLocalRx = [NSDate date];
        DEBUGLOG(currentState,@"localTransitingToStandby");
        currentState = [currentState eventStatusLocalTransitingToStandby:dict];
    }


    /*
     * REMOTE *
     */
    
    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_UNKNOWN])
    {
        _lastRemoteState=@"unknown";
        self.remoteIsFailed=NO;
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventUnknown");
        currentState = [currentState eventStatusRemoteUnknown:dict];
    }

    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_FAILED])
    {
        _lastRemoteState=@"failed";
        self.remoteIsFailed=YES;
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventRemoteFailed");
        currentState = [currentState eventStatusRemoteFailure:dict];
    }

    else if ([event isEqualToString:MESSAGE_FAILOVER])
    {
        _lastRemoteState=@"failover";
        self.remoteIsFailed=NO;
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventRemoteFailover");
        currentState = [currentState eventStatusRemoteFailover:dict];
    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_REQUEST])
    {
        _lastRemoteState=@"takeover-request";
        self.remoteIsFailed=NO;
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusRemoteTakeoverRequest");
        currentState = [currentState eventStatusRemoteTakeoverRequest:dict];
    }
    else if ([event isEqualToString:MESSAGE_TAKEOVER_REJECT])
    {
        _lastRemoteState=@"takeover-reject";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusRemoteTakeoverReject");
        currentState = [currentState eventStatusRemoteTakeoverReject:dict];
    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_CONF])
    {
        _lastRemoteState=@"takeover-confirmed";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventTakeoverConf");
        currentState = [currentState eventStatusRemoteTakeoverConf:dict];
    }
    else if ([event isEqualToString:MESSAGE_STANDBY])
    {
        _lastRemoteState=@"standby";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusStandby");
        currentState = [currentState eventStatusRemoteStandby:dict];
    }
    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_HOT])
    {
        _lastRemoteState=@"hot";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusHot");
        currentState = [currentState eventStatusRemoteHot:dict];
    }
    
    else if ([event isEqualToString:MESSAGE_TRANSITING_TO_HOT])
    {
        _lastRemoteState=@"transiting-to-hot";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusRemoteTransitingToHot");
        currentState = [currentState eventStatusRemoteTransitingToHot:dict];
    }

    else if ([event isEqualToString:MESSAGE_TRANSITING_TO_STANDBY])
    {
        _lastRemoteState=@"transiting-to-standby";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(currentState,@"eventStatusRemoteTransitingToStandby");
        currentState = [currentState eventStatusRemoteTransitingToStandby:dict];
    }


    NSAssert(currentState,@"State is now null");
    NSString *newstate = [currentState name];
    if(![oldstate isEqualToString:newstate])
    {
        NSString *s = [NSString stringWithFormat:@"State Change %@->%@",oldstate,newstate];
        [self.logFeed debugText:s];
    }
}

- (void)eventHeartbeat
{
    currentState = [currentState eventHeartbeat];
}

- (void)eventForceFailover
{
    currentState = [currentState eventStatusLocalFailure:@{}];
}

- (void)eventForceTakeover
{
    currentState = [currentState eventForceTakeover:@{}];
}

- (void)checkForTimeouts
{
    NSDate *now = [NSDate date];
    NSTimeInterval delay = [now timeIntervalSinceDate:_lastRemoteRx];
    if(delay > _timeout)
    {
        currentState = [currentState eventRemoteTimeout];
    }
    delay = [now timeIntervalSinceDate:_lastLocalRx];
    if(delay > _timeout)
    {
        currentState = [currentState eventLocalTimeout];
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
    [self.logFeed debugText:[NSString stringWithFormat:@" Executing: %s",cmd]];
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
    [self.logFeed debugText:[NSString stringWithFormat:@" Executing: %s",cmd]];
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
        dict[@"resource-id"] = resourceId;
        dict[@"local-state"] = _lastLocalState;
        dict[@"remote-state"] = _lastRemoteState;
        dict[@"lastRemoteRx"] = _lastRemoteRx ? [_lastRemoteRx stringValue] : @"-";
        dict[@"lastLocalRx"] = _lastLocalRx ? [_lastLocalRx stringValue] : @"-";
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
    if(_lastLocalRx == NULL)
    {
        _lastLocalRx = [NSDate date];
    }
    lastChecked = [NSDate date];
    NSTimeInterval delay = [lastChecked timeIntervalSinceDate:_lastLocalRx];
    if(delay > intervallDelay)
    {
        DEBUGLOG(currentState,@"eventStatusLocalFailure");
        currentState = [currentState eventStatusLocalFailure:@{}];
    }
}

@end
