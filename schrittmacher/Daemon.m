//
//  Daemon.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "Daemon.h"
#import "DaemonState_all.h"
#import "ListenerPeer.h"
#import <stdint.h>
#include <signal.h>

DaemonRandomValue GetDaemonRandomValue(void)
{
    return (DaemonRandomValue)[UMUtil random:(UINT_MAX-1)];
}

@implementation Daemon

- (Daemon *) init
{
    self = [super init];
    if(self)
    {
        _lastLocalRx = [NSDate date];
        _lastRemoteRx = [NSDate date];
        _lastLocalMessage = @"<i>nothing received yet</i>";
        _lastRemoteMessage= @"<i>nothing received yet</i>";
        _lastLocalReason=@"";
        _lastRemoteReason=@"";
        _pid = 0;
        _localIsFailed = NO; /* once we dont hear for 4 heartbeats from localtimeout we assume its dead */
        _daemonLock = [[UMMutex alloc]initWithName:@"daemonLock"];
        _startActionRunning = [[UMMutex alloc]initWithName:@"_startActionRunning"];
        _stopActionRunning = [[UMMutex alloc]initWithName:@"_stopActionRunning"];
        _activateInterfaceRunning = [[UMMutex alloc]initWithName:@"_activateInterfaceRunning"];
        _deactivateInterfaceRunning = [[UMMutex alloc]initWithName:@"_deactivateInterfaceRunning"];
    }
    return self;
}

- (void) actionStart
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
    [_heartbeatTimer start];
    UMMUTEX_LOCK(_daemonLock);
    _currentState = [startState eventStart];
    UMMUTEX_UNLOCK(_daemonLock);

}

- (void) sendStatus:(NSString *)status
{
    return [self sendStatus:status withRandomValue:0 location:NULL];
}

- (void) sendStatus:(NSString *)status location:(NSString *)location
{
    return [self sendStatus:status withRandomValue:0 location:location];
}

- (void) sendStatus:(NSString *)status withRandomValue:(DaemonRandomValue)r
{
    return [self sendStatus:status withRandomValue:r location:NULL];
}

- (void) sendStatus:(NSString *)status withRandomValue:(DaemonRandomValue)r location:(NSString *)loc
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"resource"]   = _resourceId;
    dict[@"status"]     = status;
    dict[@"priority"]   = @(_localPriority);
    dict[@"random"]     = @(r);
    dict[@"type"]       = @"schrittmacher";
    dict[@"host"]       = _localAddress;
    if(loc)
    {
        dict[@"location"]   = loc;
    }
    if(_lastLocalReason)
    {
        dict[@"reason"] = _lastLocalReason;
    }
    NSString *msg = [dict jsonString];
    if(_logLevel <=UMLOG_DEBUG)
    {
        [_logFeed debugText:[NSString stringWithFormat:@"TX %@->%@: %@",_localAddress,_remoteAddress,dict]];
        [_logFeedFile debugText:[NSString stringWithFormat:@"TX %@->%@: %@",_localAddress,_remoteAddress,dict]];
    }
     [_listener sendString:msg toAddress:_remoteAddress toPort:_port];
}


- (void) actionSendUnknown
{
    UMMUTEX_LOCK(_daemonLock);
    _randVal = GetDaemonRandomValue();
    _lastHotSent = NULL;
    _lastStandbySent = NULL;
    [self sendStatus:MESSAGE_UNKNOWN withRandomValue:_randVal];
    [_prometheusMetrics.metricSentUNK increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);

}

- (void) actionSendFailed
{
    UMMUTEX_LOCK(_daemonLock);
    [self sendStatus:MESSAGE_FAILED];
    _lastHotSent = NULL;
    _lastStandbySent = NULL;
    [_prometheusMetrics.metricSentFAIL increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) actionSendFailover
{
    UMMUTEX_LOCK(_daemonLock);
    [self sendStatus:MESSAGE_FAILOVER];
    _lastHotSent = NULL;
    _lastStandbySent = NULL;
    [_prometheusMetrics.metricSentFOVR increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) actionSendHot
{
    UMMUTEX_LOCK(_daemonLock);
    [self sendStatus:MESSAGE_HOT];
    _lastHotSent = [NSDate date];
    _lastStandbySent = NULL;
    [_prometheusMetrics.metricSentHOTT increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) actionSendStandby
{
    UMMUTEX_LOCK(_daemonLock);
    [self sendStatus:MESSAGE_STANDBY];
    _lastHotSent = NULL;
    _lastStandbySent = [NSDate date];
    [_prometheusMetrics.metricSentSTBY increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) actionSendTakeoverRequest
{
    UMMUTEX_LOCK(_daemonLock);
    _randVal = GetDaemonRandomValue();
    [self sendStatus:MESSAGE_TAKEOVER_REQUEST withRandomValue:_randVal];
    [_prometheusMetrics.metricSentTREQ increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) actionSendTakeoverRequestForced
{
    UMMUTEX_LOCK(_daemonLock);
    _randVal = GetDaemonRandomValue();
    [self sendStatus:MESSAGE_TAKEOVER_REQUEST withRandomValue:UINT_MAX];
    [_prometheusMetrics.metricSentTREQ increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) actionSendTakeoverReject
{
    UMMUTEX_LOCK(_daemonLock);
    [self sendStatus:MESSAGE_TAKEOVER_REJECT];
    [_prometheusMetrics.metricSentTREJ increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) actionSendTakeoverConfirm
{
    UMMUTEX_LOCK(_daemonLock);
    [self sendStatus:MESSAGE_TAKEOVER_CONF];
    [_prometheusMetrics.metricSentTCNF increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}


- (void) actionSendTransitingToHot
{
    UMMUTEX_LOCK(_daemonLock);
   [self sendStatus:MESSAGE_TRANSITING_TO_HOT];
    [_prometheusMetrics.metricSent2HOT increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}


- (void) actionSendTransitingToStandby
{
    UMMUTEX_LOCK(_daemonLock);
    [self sendStatus:MESSAGE_TRANSITING_TO_STANDBY];
    [_prometheusMetrics.metricSent2SBY increaseBy:1];
    UMMUTEX_UNLOCK(_daemonLock);
}

#define DEBUGLOG(state,event) \
{ \
    if(_logLevel <=UMLOG_DEBUG) \
    { \
        NSString *s = [NSString stringWithFormat:@"State:%@ event:%@",state.name,event]; \
        [self.logFeed debugText:s]; \
    } \
}

- (void) eventReceived:(NSString *)event
                  dict:(NSDictionary *)dict;
{
    UMMUTEX_LOCK(_daemonLock);
    NSString *oldstate = [_currentState name];

    NSString *reason = dict[@"reason"];
    /*
     * LOCAL MESSAGES
     */

    
    if ([event isEqualToString:MESSAGE_LOCAL_REQUEST_TAKEOVER])
    {
        _outstandingLocalHeartbeats = 0;
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"eventForceTakeover");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        else
        {
            _lastLocalReason = @"manual-requested-takeover-from-app";
        }
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"local-request-takeover";
        [self eventForceTakeover];
        [_prometheusMetrics.metricReceivedLRTO increaseBy:1];
    }
    else if ([event isEqualToString:MESSAGE_LOCAL_REQUEST_FAILOVER])
    {
        _outstandingLocalHeartbeats = 0;
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"eventForceFailover");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        else
        {
            _lastLocalReason = @"manual-requested-failover-from-app";
        }
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"local-request-failover";
        [self eventForceFailover];
        [_prometheusMetrics.metricReceivedLRFO increaseBy:1];

    }
    else if ([event isEqualToString:MESSAGE_LOCAL_HOT])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"hot";
        self.localIsFailed = NO;
        DEBUGLOG(_currentState,@"localHotIndication");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        else
        {
            _lastLocalReason = NULL;
        }

        _currentState = [_currentState eventStatusLocalHot:dict];
        [_prometheusMetrics.metricReceivedLHOT increaseBy:1];

    }
    else if ([event isEqualToString:MESSAGE_LOCAL_STANDBY])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"standby";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localStandbyIndication");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        else
        {
            _lastLocalReason = NULL;
        }
        _currentState = [_currentState eventStatusLocalStandby:dict];
        [_prometheusMetrics.metricReceivedLSBY increaseBy:1];

    }
    else if ([event isEqualToString:MESSAGE_LOCAL_UNKNOWN])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"unknown";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localUnknownIndication");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        _currentState = [_currentState eventStatusLocalUnknown:dict];
        [_prometheusMetrics.metricReceivedLUNK increaseBy:1];

    }
    else if ([event isEqualToString:MESSAGE_LOCAL_FAIL])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"fail";
        self.localIsFailed=YES;
        DEBUGLOG(_currentState,@"localFailureIndication");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        else
        {
            _lastLocalReason = @"unknown-local-failure-indication";
        }
        _currentState = [_currentState eventStatusLocalFailure:dict];
        [_prometheusMetrics.metricReceivedLFAI increaseBy:1];
    }
    
    else if ([event isEqualToString:MESSAGE_LOCAL_TRANSITING_TO_HOT])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"transiting-to-hot";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localTransitingToHot");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        else
        {
            _lastLocalReason = NULL;
        }
        _currentState = [_currentState eventStatusLocalTransitingToHot:dict];
        [_prometheusMetrics.metricReceivedL2HT increaseBy:1];
    }

    else if ([event isEqualToString:MESSAGE_LOCAL_TRANSITING_TO_STANDBY])
    {
        _outstandingLocalHeartbeats = 0;
        _lastLocalRx = [NSDate date];
        _lastLocalMessage=@"transiting-to-standby";
        self.localIsFailed=NO;
        DEBUGLOG(_currentState,@"localTransitingToStandby");
        if(reason)
        {
            _lastLocalReason = reason;
        }
        else
        {
            _lastLocalReason = NULL;
        }
        _currentState = [_currentState eventStatusLocalTransitingToStandby:dict];
        [_prometheusMetrics.metricReceivedL2SB increaseBy:1];
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
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = @"unknown-state";
        }
        _currentState = [_currentState eventStatusRemoteUnknown:dict];
        [_prometheusMetrics.metricReceivedUNK increaseBy:1];
    }

    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_FAILED])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"failed";
        self.remoteIsFailed=YES;
        DEBUGLOG(_currentState,@"eventRemoteFailed");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = @"eventRemoteFailed";
        }
        _currentState = [_currentState eventStatusRemoteFailure:dict];
        [_prometheusMetrics.metricReceivedFAIL increaseBy:1];

    }

    else if ([event isEqualToString:MESSAGE_FAILOVER])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"failover";
        self.remoteIsFailed=NO;
        DEBUGLOG(_currentState,@"eventRemoteFailover");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = @"remote-reports-failed";
        }
        _currentState = [_currentState eventStatusRemoteFailover:dict];
        [_prometheusMetrics.metricReceivedFOVR increaseBy:1];

    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_REQUEST])
    {
        _outstandingRemoteHeartbeats = 0;
       _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"takeover-request";
        self.remoteIsFailed=NO;
        DEBUGLOG(_currentState,@"eventStatusRemoteTakeoverRequest");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = NULL;
        }
        _currentState = [_currentState eventStatusRemoteTakeoverRequest:dict];
        [_prometheusMetrics.metricReceivedTREQ increaseBy:1];

    }
    else if ([event isEqualToString:MESSAGE_TAKEOVER_REJECT])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"takeover-reject";
        DEBUGLOG(_currentState,@"eventStatusRemoteTakeoverReject");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = NULL;
        }

        _currentState = [_currentState eventStatusRemoteTakeoverReject:dict];
        [_prometheusMetrics.metricReceivedTREJ increaseBy:1];

    }

    else if ([event isEqualToString:MESSAGE_TAKEOVER_CONF])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"takeover-confirmed";
        DEBUGLOG(_currentState,@"eventTakeoverConf");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = NULL;
        }

        _currentState = [_currentState eventStatusRemoteTakeoverConf:dict];
        [_prometheusMetrics.metricReceivedTCNF increaseBy:1];

    }
    else if ([event isEqualToString:MESSAGE_STANDBY])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteMessage=@"standby";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(_currentState,@"eventStatusStandby");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = @"remote-reports-standby";
        }
        _currentState = [_currentState eventStatusRemoteStandby:dict];
        [_prometheusMetrics.metricReceivedSTBY increaseBy:1];

    }
    /* the other side says it doesnt know its status */
    else if ([event isEqualToString:MESSAGE_HOT])
    {
        _outstandingRemoteHeartbeats = 0;
       _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"hot";
        DEBUGLOG(_currentState,@"eventStatusHot");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = NULL;
        }
        _currentState = [_currentState eventStatusRemoteHot:dict];
        [_prometheusMetrics.metricReceivedHOTT increaseBy:1];
    }
    
    else if ([event isEqualToString:MESSAGE_TRANSITING_TO_HOT])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteMessage=@"transiting-to-hot";
        _lastRemoteRx = [NSDate date];
        DEBUGLOG(_currentState,@"eventStatusRemoteTransitingToHot");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = NULL;
        }
        _currentState = [_currentState eventStatusRemoteTransitingToHot:dict];
        [_prometheusMetrics.metricReceived2HOT increaseBy:1];
    }

    else if ([event isEqualToString:MESSAGE_TRANSITING_TO_STANDBY])
    {
        _outstandingRemoteHeartbeats = 0;
        _lastRemoteRx = [NSDate date];
        _lastRemoteMessage=@"transiting-to-standby";
        DEBUGLOG(_currentState,@"eventStatusRemoteTransitingToStandby");
        if(reason)
        {
            _lastRemoteReason = reason;
        }
        else
        {
            _lastRemoteReason = NULL;
        }
        _currentState = [_currentState eventStatusRemoteTransitingToStandby:dict];
        [_prometheusMetrics.metricReceived2SBY increaseBy:1];
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
        NSString *s;
        if(reason)
        {
            s = [NSString stringWithFormat:@"State Change %@->%@ (%@)",oldstate,newstate,reason];
        }
        else
        {
            s = [NSString stringWithFormat:@"State Change %@->%@",oldstate,newstate];
        }
        [_logFeed infoText:s];
        [_logFeedFile infoText:s];
    }
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) eventHeartbeat
{
    UMMUTEX_LOCK(_daemonLock);
    if(_currentState==NULL)
    {
        NSLog(@"ouch. currentState is NULL! assuming unknown");
        _currentState = [[DaemonState_Unknown alloc]init];
    }
    _currentState = [_currentState eventHeartbeat];
    [self checkForTimeouts];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) eventForceFailover
{
    UMMUTEX_LOCK(_daemonLock);
    if(_currentState==NULL)
    {
        NSLog(@"ouch. currentState is NULL! assuming unknown");
        _currentState = [[DaemonState_Unknown alloc]init];
    }
    _currentState = [_currentState eventStatusLocalFailure:@{}];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) eventForceTakeover
{
    UMMUTEX_LOCK(_daemonLock);
    if(_currentState==NULL)
    {
        NSLog(@"ouch. currentState is NULL! assuming unknown");
        _currentState = [[DaemonState_Unknown alloc]init];
    }
    _currentState = [_currentState eventForceTakeover:@{}];
    UMMUTEX_UNLOCK(_daemonLock);
}

- (void) checkForTimeouts
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
        _lastLocalReason = @"eventLocalTimeout issued due to outstanding local heartbeats";
        [_logFeed infoText:_lastLocalReason];
        [_logFeedFile infoText:_lastLocalReason];
        _currentState = [_currentState eventLocalTimeout];
    }

    if(_outstandingRemoteHeartbeats > 4)
    {
        _lastRemoteReason = @"eventRemoteTimeout issued due to outstanding remote heartbeats";
        [_logFeed infoText:_lastRemoteReason];
        [_logFeedFile infoText:_lastRemoteReason];
        _currentState = [_currentState eventRemoteTimeout];
    }
}

#define     SETENV(a,b)   if(b!=NULL) { setenv(a,b.UTF8String,1);  } else { unsetenv(a); }

- (void) setEnvVars
{
    NSString *heartbeatIntervall = [NSString stringWithFormat:@"%lf",_intervallDelay];
    SETENV("NETMASK",  _netmask);
    SETENV("LOCAL_ADDRESS",  _localAddress);
    SETENV("REMOTE_ADDRESS", _remoteAddress);
    SETENV("SHARED_ADDRESS", _sharedAddress);
    SETENV("RESOURCE_NAME", _resourceId);
    SETENV("PID_FILE", _pidFile);
    SETENV("LAST_LOCAL_REASON",_lastLocalReason);
    SETENV("LAST_REMOTE_REASON",_lastRemoteReason);
    if(_pid > 0)
    {
        NSString *p = [NSString stringWithFormat:@"%ld",_pid];
        SETENV("RESOURCE_PID",p);
    }
    else
    {
        unsetenv("RESOURCE_PID");
    }
    SETENV("HEARTBEAT_INTERVAL", heartbeatIntervall);
}


- (void) unsetEnvVars
{
    unsetenv("NETMASK");
    unsetenv("LOCAL_ADDRESS");
    unsetenv("REMOTE_ADDRESS");
    unsetenv("SHARED_ADDRESS");
    unsetenv("RESOURCE_NAME");
    unsetenv("PID_FILE");
    unsetenv("LAST_LOCAL_REASON");
    unsetenv("LAST_REMOTE_REASON");
    unsetenv("RESOURCE_PID");
    unsetenv("HEARTBEAT_INTERVAL");
    
    unsetenv("ACTION");
}

- (int) executeScript:(NSString *)command
{
    int r=0;
    if(command.length==0) /* empty script is always a success */
    {
        return 0;
    }
    [_logFeed debugText:[NSString stringWithFormat:@" Executing: %@",command]];
    if(_logLevel <= UMLOG_DEBUG)
    {
        [_logFeedFile debugText:[NSString stringWithFormat:@" Executing: %@",command]];
    }
    NSArray *cmd_array = [command componentsSeparatedByCharactersInSet:[UMUtil whitespaceAndNewlineCharacterSet]];
    NSArray *lines = [UMUtil readChildProcess:cmd_array];
    r=0;
    if(_logLevel <= UMLOG_DEBUG)
    {
        NSString *allLines = [lines componentsJoinedByString:@"\n"];
        [_logFeed debugText:allLines];
        [_logFeedFile debugText:allLines];
    }
    return r;
}


- (void) callActivateInterface
{
    if(_activateInterfaceCommand.length == 0)
    {
        self.interfaceState = DaemonInterfaceState_Unknown;
    }
    else
    {
        if(self.interfaceState != DaemonInterfaceState_Up)
        {
            [self runSelectorInBackground:@selector(callActivateInterfaceBackground)];
        }
    }
}

- (void) callActivateInterfaceBackground
{
    int result = 0;
    UMMUTEX_TRYLOCK(_activateInterfaceRunning, 10, 0.1, result);
    if(result != 0)
    {
        [_logFeed infoText:@"*** callActivateInterface while LOCK was held over 10 seconds ***"];
    }
    else
    {
        [_logFeed infoText:@"*** callActivateInterface ***"];
    }
    [self setEnvVars];
    setenv("ACTION", "activate", 1);
    [self executeScript:_activateInterfaceCommand];
    [self unsetEnvVars];
    _activatedAt = [NSDate date];
    self.interfaceState = DaemonInterfaceState_Up;
    UMMUTEX_UNLOCK(_activateInterfaceRunning);
}

- (void) callDeactivateInterface
{
    if(_deactivateInterfaceCommand.length == 0)
    {
        self.interfaceState = DaemonInterfaceState_Unknown;
    }
    else
    {
        if(self.interfaceState != DaemonInterfaceState_Down)
        {
            [self runSelectorInBackground:@selector(callDeactivateInterfaceBackground)];
        }
    }
}

- (void) callDeactivateInterfaceBackground
{
    int result = 0;
    UMMUTEX_TRYLOCK(_deactivateInterfaceRunning, 10, 0.1, result);
    if(result != 0)
    {
        [_logFeed infoText:@"*** callDeactivateInterface while LOCK was held over 10 seconds ***"];
    }
    else
    {
        [_logFeed infoText:@"*** callDeactivateInterface ***"];
    }
    [self setEnvVars];
    setenv("ACTION", "deactivate", 1);
    [self executeScript:_deactivateInterfaceCommand];
    [self unsetEnvVars];
    _deactivatedAt = [NSDate date];
    self.interfaceState = DaemonInterfaceState_Down;
    if(result==0)
    {
        UMMUTEX_UNLOCK(_deactivateInterfaceRunning);
    }
}


- (void) callStartAction
{
    [self runSelectorInBackground:@selector(callStartActionBackground)];
}

- (void) callStartActionBackground
{
    int result = 0;
    UMMUTEX_TRYLOCK(_startActionRunning, 10, 0.1, result);
    if(result != 0)
    {
        [_logFeed infoText:@"*** callStartAction while LOCK was held over 10 seconds ***"];
    }
    else
    {
        [_logFeed infoText:@"*** callStartAction ***"];
    }
    [_prometheusMetrics.metricsStartActionRequested increaseBy:1];
    self.localStartActionRequested = YES;
    if(_startAction.length > 0)
    {
        [self setEnvVars];
        setenv("ACTION", "start", 1);
        [self executeScript:_startAction];
        [self unsetEnvVars];
    }
    else if(_pid != 0)
    {
        kill((pid_t)_pid,SIGUSR1);
    }
    _startedAt = [NSDate date];
    if(result==0)
    {
        UMMUTEX_UNLOCK(_startActionRunning);
    }
}


- (void) callStopAction
{
    [self runSelectorInBackground:@selector(callStopActionBackground)];
}

- (void) callStopActionBackground
{
    
    int result = 0;
    UMMUTEX_TRYLOCK(_stopActionRunning, 10, 0.1, result);
    if(result != 0)
    {
        [_logFeed infoText:@"*** callStopAction while LOCK was held over 10 seconds ***"];
    }
    else
    {
        [_logFeed infoText:@"*** callStopAction ***"];
    }
    [_prometheusMetrics.metricsStopActionRequested increaseBy:1];
    self.localStopActionRequested = YES;
    if(_stopAction.length > 0)
    {
        [self setEnvVars];
        setenv("ACTION", "stop", 1);
        [self executeScript:_stopAction];
        [self unsetEnvVars];
    }
    else if(_pid != 0)
    {
        kill((pid_t)_pid,SIGUSR2);
    }
    _stoppedAt = [NSDate date];
    if(result==0)
    {
        UMMUTEX_UNLOCK(_stopActionRunning);
    }
}

- (void)fireUp
{
    [self callActivateInterface];
    [self callStartAction];
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
        if(_lastLocalReason.length > 0)
        {
            dict[@"last-local-reason"] = _lastLocalReason;
        }
        else
        {
            dict[@"last-local-reason"] = @"";
        }
        if(_lastRemoteReason.length > 0)
        {
            dict[@"last-remote-reason"] = _lastRemoteReason;
        }
        else
        {
            dict[@"last-remote-reason"] = @"";
        }
        NSString *s = [_daemonLock lockStatusDescription];
        if(s.length > 0)
        {
            dict[@"lock"] = s;
        }
    }
    return dict;
}

@end
