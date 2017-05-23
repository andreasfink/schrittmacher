//
//  Daemon.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "Daemon.h"
#import "DaemonState_all.h"
#import "Listener.h"

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
@synthesize startupDelay;
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
    NSLog(@"TX %@->%@: %@",localAddress,remoteAddress,dict);
    [listener sendString:msg toAddress:remoteAddress toPort:remotePort];
}


- (void)actionSendUnknown:(DaemonRandomValue)r
{
    [self sendStatus:MESSAGE_UNKNOWN withRandomValue:r];
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

- (void)actionSendTakeoverRequest:(DaemonRandomValue)r
{
    [self sendStatus:MESSAGE_TAKEOVER_REQUEST withRandomValue:r];
}

- (void)actionSendTakeoverReject
{
    [self sendStatus:MESSAGE_TAKEOVER_REJECT];
}

- (void)actionSendTakeoverConfirm
{
    [self sendStatus:MESSAGE_TAKEOVER_CONF];
}

#define DEBUGLOG(state,event) NSLog(@"State:%@ event:%@",state.name,event)

- (void)eventReceived:(NSString *)event
         withPriority:(int)prio
          randomValue:(DaemonRandomValue)r
          fromAddress:(NSString *)address
{
    NSString *oldstate = [currentState name];

    if(([address isEqualToString:@"127.0.0.1"])
       || ([address isEqualToString:@"::1"])
       || ([address isEqualToString:@"localhost"]))
    {
        /*local message */
        if ([event isEqualToString:MESSAGE_LOCAL_HOT])
        {
            lastLocalRx = [NSDate date];
            DEBUGLOG(currentState,@"localHotIndication");
            currentState = [currentState localHotIndication];
            inStartupPhase = NO;
        }
        else if ([event isEqualToString:MESSAGE_LOCAL_STANDBY])
        {
            lastLocalRx = [NSDate date];
            DEBUGLOG(currentState,@"localStandbyIndication");
            currentState = [currentState localStandbyIndication];
            inStartupPhase = NO;
        }
        else if ([event isEqualToString:MESSAGE_LOCAL_UNKNOWN])
        {
            lastLocalRx = [NSDate date];
            DEBUGLOG(currentState,@"localUnknownIndication");
            currentState = [currentState localUnknownIndication];
            inStartupPhase = NO;
        }
        else if ([event isEqualToString:MESSAGE_LOCAL_FAIL])
        {
            lastLocalRx = [NSDate date];
            DEBUGLOG(currentState,@"localFailureIndication");
            currentState = [currentState localFailureIndication];
            inStartupPhase = NO;
        }
        else
        {
            NSString *s = [NSString stringWithFormat:@"Unexpected event '%@'",event];
            DEBUGLOG(currentState,s);
        }
    }
    else
    {
       /* the other side says it doesnt know its status */
        if ([event isEqualToString:MESSAGE_UNKNOWN])
        {
            lastRx = [NSDate date];
            DEBUGLOG(currentState,@"eventUnknown");
            currentState = [currentState eventUnknown:prio randomValue:(long int)r];
        }

        /* the other side says it doesnt know its status */
        else if ([event isEqualToString:MESSAGE_FAILED])
        {
            lastRx = [NSDate date];
            DEBUGLOG(currentState,@"eventRemoteFailed");
            currentState = [currentState eventRemoteFailed];
        }
        else if ([event isEqualToString:MESSAGE_TAKEOVER_REQUEST])
        {
            lastRx = [NSDate date];
            DEBUGLOG(currentState,@"eventTakeoverRequest");
            currentState = [currentState eventTakeoverRequest:prio randomValue:r];
        }
        else if ([event isEqualToString:MESSAGE_TAKEOVER_REJECT])
        {
            lastRx = [NSDate date];
            DEBUGLOG(currentState,@"eventTakeoverReject");
            currentState = [currentState eventTakeoverReject:prio];
        }

        else if ([event isEqualToString:MESSAGE_TAKEOVER_CONF])
        {
            lastRx = [NSDate date];
            DEBUGLOG(currentState,@"eventTakeoverConf");
            currentState = [currentState eventTakeoverConf:prio];
        }
        else if ([event isEqualToString:MESSAGE_STANDBY])
        {
            lastRx = [NSDate date];
            DEBUGLOG(currentState,@"eventStatusStandby");
            currentState = [currentState eventStatusStandby:prio];
        }
        /* the other side says it doesnt know its status */
        else if ([event isEqualToString:MESSAGE_HOT])
        {
            lastRx = [NSDate date];
            DEBUGLOG(currentState,@"eventStatusHot");
            currentState = [currentState eventStatusHot:prio];
        }
    }
    NSAssert(currentState,@"State is now null");
    NSString *newstate = [currentState name];
    if(![oldstate isEqualToString:newstate])
    {
        NSLog(@"State Change %@->%@",oldstate,newstate);
    }
}

- (void)eventTimer
{
    currentState = [currentState eventTimer];
}

- (void)eventForceFailover
{
    currentState = [currentState localFailureIndication];
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

- (int)goToHot /* returns success */
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

- (int)goToStandby
{
    return [self shutItDown];
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
    NSLog(@" Executing: %s",cmd);
    return system(cmd);
}


- (int)callActivateInterface
{
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
    }
    return r;

}


- (int) callDeactivateInterface
{
    if(deactivateInterfaceCommand.length == 0)
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
    }
    return r;

}

- (int)callStartAction
{
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
    if(stopAction.length == 0)
    {
        return 0;
    }
    [self setEnvVars];
    setenv("ACTION", "stop", 1);
    const char *cmd = stopAction.UTF8String;
    NSLog(@" Executing: %s",cmd);
    int r = system(cmd);
    [self unsetEnvVars];
    if(r==0)
    {
        stoppedAt = [NSDate date];
    }
    return r;
}


- (int)shutItDown
{
    int r1 = [self callStopAction];
    int r2 = [self callDeactivateInterface];
    inStartupPhase = YES;
    if(r1!=0)
    {
        return r1;
    }
    return r2;
}


- (int)fireUp
{
    int r1 = [self callActivateInterface];
    int r2 = [self callStartAction];
    inStartupPhase = YES;
    if(r1!=0)
    {
        return r1;
    }
    return r2;

}

- (NSDictionary *)status
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"resource-id"]= resourceId;
    dict[@"current-state"]=[currentState name];
    dict[@"lastRx"] = lastRx ? [lastRx stringValue] : @"-";
    dict[@"lastLocalRx"] = lastLocalRx ? [lastLocalRx stringValue] : @"-";
    dict[@"remoteAddress"] = remoteAddress;
    dict[@"localAddress"] = localAddress;
    dict[@"sharedAddress"] = sharedAddress;
    dict[@"startAction"] = startAction;
    dict[@"stopAction"] = stopAction;
    dict[@"pidFile"] = pidFile;
    dict[@"activateInterfaceCommand"] = activateInterfaceCommand;
    dict[@"deactivateInterfaceCommand"] = deactivateInterfaceCommand;
    dict[@"localPriority"] = [NSString stringWithFormat:@"%d",(int)localPriority];
    dict[@"lastChecked"] = [lastChecked stringValue];
    dict[@"inStartupPhase"] = inStartupPhase ? @"YES" : @"NO";
    dict[@"startedAt"] = startedAt ? [startedAt stringValue] : @"never";
    dict[@"stoppedAt"] = stoppedAt ? [stoppedAt stringValue] : @"never";
    dict[@"activatedAt"] = activatedAt ? [activatedAt stringValue] : @"never";
    dict[@"dectivatedAt"] = deactivatedAt ? [deactivatedAt stringValue] : @"never";
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
    if(inStartupPhase)
    {
        if(delay > startupDelay)
        {
            DEBUGLOG(currentState,@"localFailureIndication");
            currentState = [currentState localFailureIndication];
        }
    }
    else
    {
        if(delay > intervallDelay)
        {
            DEBUGLOG(currentState,@"localFailureIndication");
            currentState = [currentState localFailureIndication];
        }
    }
}
@end
