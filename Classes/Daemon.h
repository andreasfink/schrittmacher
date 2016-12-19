//
//  Daemon.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <ulib/ulib.h>

#import "DaemonRandomValue.h"

#define MESSAGE_UNKNOWN             @"UNK"
#define MESSAGE_HOT                 @"HOTT"
#define MESSAGE_STANDBY             @"STBY"
#define MESSAGE_TAKEOVER_REQUEST    @"TREQ"
#define MESSAGE_TAKEOVER_CONF       @"TCNF"
#define MESSAGE_TAKEOVER_REJECT     @"TREJ"
#define MESSAGE_FAILED              @"FAIL"

#define MESSAGE_LOCAL_HOT           @"LHOT"
#define MESSAGE_LOCAL_STANDBY       @"LSBY"
#define MESSAGE_LOCAL_UNKNOWN       @"LUNK"
#define MESSAGE_LOCAL_FAIL          @"LFAI"


#define GOTO_HOT_SUCCESS            1
#define GOTO_HOT_ALREADY_HOT        2
#define GOTO_HOT_FAILED             0


@class DaemonState;
@class Listener;

@interface Daemon : UMObject
{
    DaemonState     *currentState;
    NSString        *resourceId;
    int             localPriority;
    BOOL            iAmHot;
    NSString        *remoteAddress;
    NSString        *localAddress;
    NSString        *sharedAddress;
    NSString        *netmask;
    int             remotePort;
    Listener        *listener;
    NSTimeInterval  timeout;
    NSDate          *lastRx;
    NSDate          *lastLocalRx;
    NSString        *startAction;
    NSString        *stopAction;
    NSString        *pidFile;
    NSString        *activateInterfaceCommand;
    NSString        *deactivateInterfaceCommand;
    BOOL            inStartupPhase;
    NSTimeInterval  startupDelay; /* how long does it take to fire up the daemon until we get its heartbeat */
    NSTimeInterval  intervallDelay; /* how often do we get local heartbeat */
    NSDate          *lastChecked;
    NSDate          *activatedAt;
    NSDate          *deactivatedAt;
    NSDate          *startedAt;
    NSDate          *stoppedAt;
}

@property (readwrite,strong) DaemonState *currentState;
@property (readwrite,assign) int        localPriority;
@property (readwrite,strong) NSString   *resourceId;
@property (readwrite,strong) NSString   *remoteAddress;
@property (readwrite,strong) NSString   *localAddress;
@property (readwrite,strong) NSString   *netmask;
@property (readwrite,strong) NSString   *sharedAddress;
@property (readwrite,assign) int        remotePort;

@property (readwrite,strong) Listener        *listener;
@property (readwrite,assign) NSTimeInterval  timeout;
@property (readwrite,strong) NSDate          *lastRx;
@property (readwrite,strong) NSDate          *lastLocalRx;
@property (readwrite,strong) NSString        *startAction;
@property (readwrite,strong) NSString        *stopAction;
@property (readwrite,strong) NSString        *pidFile;

@property (readwrite,strong) NSString *activateInterfaceCommand;
@property (readwrite,strong) NSString *deactivateInterfaceCommand;
@property (readwrite,assign) NSTimeInterval  startupDelay;
@property (readwrite,assign) NSTimeInterval  intervallDelay;

- (void)eventReceived:(NSString *)event
         withPriority:(int)prio
          randomValue:(DaemonRandomValue)r
          fromAddress:(NSString *)address;


- (void)eventTimer;

- (void)actionStart;

- (void)actionSendUnknown:(DaemonRandomValue)r;
- (void)actionSendFailed;
- (void)actionSendHot;
- (void)actionSendStandby;
- (void)actionSendTakeoverRequest:(DaemonRandomValue)r;
- (void)actionSendTakeoverReject;
- (void)actionSendTakeoverConfirm;

- (void)sendStatus:(NSString *)status;

- (int)goToHot; /* returns success */
- (void)goToStandby;
- (void)fireUp;
- (void)shutItDown;
- (void)checkForTimeouts;
- (NSDictionary *)status;
- (void)eventForceFailover;


- (void)callDeactivateInterface;
- (void)callActivateInterface;
- (void)callStopAction;
- (void)callStartAction;
- (void)executeScript:(NSString *)command;
- (void)checkIfUp;

@end
