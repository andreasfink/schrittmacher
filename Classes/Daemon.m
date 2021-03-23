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

- (Daemon *)init
{
    self = [super init];
    if(self)
    {
        _lastLocalRx = [NSDate date];
        _lastRemoteRx = [NSDate date];
        _lastLocalMessage = @"<i>nothing received yet</i>";
        _lastRemoteMessage= @"<i>nothing received yet</i>";
    }
    return self;
}

- (void)actionStart
{
    if(_timeout<=0)
    {
        _timeout=6.0;
    }
    if(_timeout > 60)
    {
        _timeout = 6;
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
    _currentState = [startState eventStart];
}

- (void)sendStatus:(NSString *)status
{
    return [self sendStatus:status withRandomValue:0];
}

- (void)sendStatus:(NSString *)status withRandomValue:(DaemonRandomValue)r
{
    NSDictionary *dict = @{ @"resource" : _resourceId,
                            @"status"   : status,
                            @"priority" : @(_localPriority),
                            @"random"   : @(r)};
    
    NSString *msg = [dict jsonString];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [_logFeed debugText:[NSString stringWithFormat:@"TX %@->%@: %@",_localAddress,_remoteAddress,dict]];
    }
    [_listener sendString:msg toAddress:_remoteAddress toPort:_remotePort];
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
    if(_logLevel <=UMLOG_DEBUG) \
    { \
        NSString *s = [NSString stringWithFormat:@"State:%@ event:%@",state.name,event]; \
        [self.logFeed debugText:s]; \
    } \
}

- (void)eventReceived:(NSString *)event
                 dict:(NSDictionary *)dict;
{
    NSString *oldstate = [_currentState name];
   
    /*
     * LOCAL MESSAGES
     */

    if ([event isEqualToString:MESSAGE_LOCAL_REQUEST_TAKEOVER])
    {
        _outstandingLocalHeartbeats = 0;
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"eventForceTakeover");
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"local-request-takeover";
        [self eventForceTakeover];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_REQUEST_FAILOVER])
    {
        _outstandingLocalHeartbeats = 0;
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"eventForceFailover");
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"local-request-failover";
        [self eventForceFailover];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_HOT])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"hot";
        self.localIsFailed = NO;
        DEBUGLOG(_currentState,@"localHotIndication");
        _currentState = [_currentState eventStatusLocalHot:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_STANDBY])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"standby";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localStandbyIndication");
        _currentState = [_currentState eventStatusLocalStandby:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_UNKNOWN])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"unknown";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localUnknownIndication");
        _currentState = [_currentState eventStatusLocalUnknown:dict];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_FAIL])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"fail";
        self.localIsFailed=YES;
        DEBUGLOG(_currentState,@"localFailureIndication");
        _currentState = [_currentState eventStatusLocalFailure:dict];
    }
    
    else if ([event isEqualToString:MESSAGE_LOCAL_TRANSITING_TO_HOT])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"transiting-to-hot";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localTransitingToHot");
        _currentState = [_currentState eventStatusLocalTransitingToHot:dict];
    }

    else if ([event isEqualToString:MESSAGE_LOCAL_TRANSITING_TO_STANDBY])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"transiting-to-standby";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localTransitingToStandby");
        _currentState = [_currentState eventStatusLocalTransitingToStandby:dict];
    }


    /*
     * REMOTE *
     */
    
    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_UNKNOWN])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"unknown";
        self.remoteIsFailed=NO;
        DEBUGLOG(_currentState,@"eventUnknown");
        _currentState = [_currentState eventStatusRemoteUnknown:dict];
    }

    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_FAILED])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"failed";
        self.remoteIsFailed=YES;
        DEBUGLOG(_currentState,@"eventRemoteFailed");
        _currentState = [_currentState eventStatusRemoteFailure:dict];
    }

    else if ([event isEqualToString:MESSAGE_FAILOVER])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"failover";
        self.remoteIsFailed=NO;
        DEBUGLOG(_currentState,@"eventRemoteFailover");
        _currentState = [_currentState eventStatusRemoteFailover:dict];
    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_REQUEST])
    {
        _outstandingRemoteHeartbeats = 0;
       _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"takeover-request";
        self.remoteIsFailed=NO;
        DEBUGLOG(_currentState,@"eventStatusRemoteTakeoverRequest");
        _currentState = [_currentState eventStatusRemoteTakeoverRequest:dict];
    }
    else if ([event isEqualToString:MESSAGE_TAKEOVER_REJECT])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"takeover-reject";
        DEBUGLOG(_currentState,@"eventStatusRemoteTakeoverReject");
        _currentState = [_currentState eventStatusRemoteTakeoverReject:dict];
    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_CONF])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"takeover-confirmed";
        DEBUGLOG(_currentState,@"eventTakeoverConf");
        _currentState = [_currentState eventStatusRemoteTakeoverConf:dict];
    }
    else if ([event isEqualToString:MESSAGE_STANDBY])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteMessage=@"standby";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(_currentState,@"eventStatusStandby");
        _currentState = [_currentState eventStatusRemoteStandby:dict];
    }
    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_HOT])
    {
        _outstandingRemoteHeartbeats = 0;
       _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"hot";
        DEBUGLOG(_currentState,@"eventStatusHot");
        _currentState = [_currentState eventStatusRemoteHot:dict];
    }
    
    else if ([event isEqualToString:MESSAGE_TRANSITING_TO_HOT])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteMessage=@"transiting-to-hot";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(_currentState,@"eventStatusRemoteTransitingToHot");
        _currentState = [_currentState eventStatusRemoteTransitingToHot:dict];
    }

    else if ([event isEqualToString:MESSAGE_TRANSITING_TO_STANDBY])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"transiting-to-standby";
        DEBUGLOG(_currentState,@"eventStatusRemoteTransitingToStandby");
        _currentState = [_currentState eventStatusRemoteTransitingToStandby:dict];
    }
    else
    {
        if(_logLevel <=UMLOG_DEBUG)
        {
            NSString *s = [NSString stringWithFormat:@"State:%@ UnknownEvent:%@ dict:%@",_currentState.name,event,dict.jsonString];
            [self.logFeed debugText:s];
        }
    }
    NSAssert(_currentState,@"State is now null");
    NSString *newstate = [_currentState name];
    if(![oldstate isEqualToString:newstate])
    {
        NSString *s = [NSString stringWithFormat:@"State Change %@->%@",oldstate,newstate];
        [_logFeed infoText:s];
    }
}

- (void)eventHeartbeat
{
    if(_currentState==NULL)
    {
        NSLog(@"ouch. currentState is NULL! assuming unknown");
        _currentState = [[DaemonState_Unknown alloc]init];
    }
    _currentState = [_currentState eventHeartbeat];
}

- (void)eventForceFailover
{
    if(_currentState==NULL)
    {
        NSLog(@"ouch. currentState is NULL! assuming unknown");
        _currentState = [[DaemonState_Unknown alloc]init];
    }
    _currentState = [_currentState eventStatusLocalFailure:@{}];
}

- (void)eventForceTakeover
{
    if(_currentState==NULL)
    {
        NSLog(@"ouch. currentState is NULL! assuming unknown");
        _currentState = [[DaemonState_Unknown alloc]init];
    }
    _currentState = [_currentState eventForceTakeover:@{}];
}

- (void)checkForTimeouts
{
    if(_currentState==NULL)
    {
        NSLog(@"ouch. currentState is NULL! assuming unknown");
        _currentState = [[DaemonState_Unknown alloc]init];
    }
    _outstandingLocalHeartbeats++;
    _outstandingRemoteHeartbeats++;
    if(_outstandingLocalHeartbeats > 4)
    {
        _currentState = [_currentState eventLocalTimeout];
    }

    if(_outstandingRemoteHeartbeats > 4)
    {
        _currentState = [_currentState eventRemoteTimeout];
    }
}

- (int)goToHot /* returns 0 on success  */
{
    if(!_iAmHot)
    {
        int r = [self fireUp];
        if(r==0)
        {
            _iAmHot = YES;
            return GOTO_HOT_SUCCESS;
        }
        else
        {
            _iAmHot = NO;
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
    NSString *heartbeatIntervall = [NSString stringWithFormat:@"%lf",_intervallDelay];
    SETENV("NETMASK",  _netmask);
    SETENV("LOCAL_ADDRESS",  _localAddress);
    SETENV("REMOTE_ADDRESS", _remoteAddress);
    SETENV("SHARED_ADDRESS", _sharedAddress);
    SETENV("RESOURCE_NAME", _resourceId);
    SETENV("PID_FILE", _pidFile);
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
    if(_logLevel <= UMLOG_DEBUG)
    {
        [_logFeed debugText:[NSString stringWithFormat:@" Executing: %s",cmd]];
    }
    return system(cmd);
}


- (int)callActivateInterface
{
    if(self.interfaceState == DaemonInterfaceState_Up)
    {
        return 0;
    }

    if(_activateInterfaceCommand.length == 0)
    {
        return 0;
    }
    [self setEnvVars];
    setenv("ACTION", "activate", 1);
    int r = [self executeScript:_activateInterfaceCommand];
    [self unsetEnvVars];
    if(r==0)
    {
        _activatedAt = [NSDate date];
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
    int r = [self executeScript:_deactivateInterfaceCommand];
    [self unsetEnvVars];
    if(r==0)
    {
        _deactivatedAt = [NSDate date];
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
    if(_startAction.length == 0)
    {
        return 0;
    }
    [self setEnvVars];
    setenv("ACTION", "start", 1);
    int r = [self executeScript:_startAction];
    [self unsetEnvVars];
    if(r==0)
    {
        _startedAt = [NSDate date];
    }
    return r;
}

-(int)callStopAction
{
    self.localStopActionRequested = YES;
    
    if(_stopAction.length == 0)
    {
        return 0;
    }
    [self setEnvVars];
    setenv("ACTION", "stop", 1);
    const char *cmd = _stopAction.UTF8String;
    if(_logLevel <= UMLOG_DEBUG)
    {
        [_logFeed debugText:[NSString stringWithFormat:@" Executing: %s",cmd]];
    }
    int r = system(cmd);
    [self unsetEnvVars];
    if(r==0)
    {
        _stoppedAt = [NSDate date];
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
        dict[@"resource-id"] = _resourceId;
        dict[@"state"] = _currentState.name;
        dict[@"last-local-message"] = _lastLocalMessage;
        dict[@"last-remote-message"] = _lastRemoteMessage;
        dict[@"last-remote-message-received"] = _lastRemoteRx ? [_lastRemoteRx stringValue] : @"-";
        dict[@"last-local-message-received"] = _lastLocalRx ? [_lastLocalRx stringValue] : @"-";
        dict[@"remote-address"] = _remoteAddress;
        dict[@"local-address"] = _localAddress;
        dict[@"shared-address"] = _sharedAddress;
        dict[@"start-action"] = _startAction;
        dict[@"stop-action"] = _stopAction;
        dict[@"activate-interface-command"] = _activateInterfaceCommand;
        dict[@"deactivate-interface-command"] = _deactivateInterfaceCommand;
        dict[@"local-priority"] = [NSString stringWithFormat:@"%d",(int)_localPriority];
        dict[@"last-checked"] = [_lastChecked stringValue];
        dict[@"started-at"] = _startedAt ? [_startedAt stringValue] : @"never";
        dict[@"stopped-at"] = _stoppedAt ? [_stoppedAt stringValue] : @"never";
        dict[@"activated-at"] = _activatedAt ? [_activatedAt stringValue] : @"never";
        dict[@"dectivated-at"] = _deactivatedAt ? [_deactivatedAt stringValue] : @"never";
        dict[@"remote-is-failed"] = _remoteIsFailed ? @"YES" : @"NO";
        dict[@"local-is-failed"] = _localIsFailed ? @"YES" : @"NO";
    }
    return dict;
}


- (void)checkIfUp
{
    /* we check if we have received the heartbeat from the local instance */
    if(_lastLocalRx == NULL)
    {
        _lastLocalRx = [NSDate date];
        return;
    }
    _lastChecked = [NSDate date];
    NSTimeInterval delay = [_lastChecked timeIntervalSinceDate:_lastLocalRx];
    if(delay > (3 * _intervallDelay)) /* if we have not heard anything for 3 * heartbeat delay from the local
                                         host, we assume its dead this is normally 6 seconds. */
    {
        DEBUGLOG(_currentState,@"eventStatusLocalFailure");
        _currentState = [_currentState eventStatusLocalFailure:@{}];
    }
}

@end
