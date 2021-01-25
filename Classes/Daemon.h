//
//  Daemon.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>

#define MESSAGE_UNKNOWN                     @"UNK"
#define MESSAGE_HOT                         @"HOTT"
#define MESSAGE_STANDBY                     @"STBY"
#define MESSAGE_TAKEOVER_REQUEST            @"TREQ"
#define MESSAGE_TAKEOVER_CONF               @"TCNF"
#define MESSAGE_TAKEOVER_REJECT             @"TREJ"
#define MESSAGE_FAILED                      @"FAIL"
#define MESSAGE_FAILOVER                    @"FOVR"
#define MESSAGE_TRANSITING_TO_HOT           @"2HOT"
#define MESSAGE_TRANSITING_TO_STANDBY       @"2SBY"

#define MESSAGE_LOCAL_HOT                   @"LHOT"
#define MESSAGE_LOCAL_STANDBY               @"LSBY"
#define MESSAGE_LOCAL_UNKNOWN               @"LUNK"
#define MESSAGE_LOCAL_FAIL                  @"LFAI"
#define MESSAGE_LOCAL_TRANSITING_TO_HOT     @"L2HT"
#define MESSAGE_LOCAL_TRANSITING_TO_STANDBY @"L2SB"

#define GOTO_HOT_SUCCESS                    1
#define GOTO_HOT_ALREADY_HOT                2
#define GOTO_HOT_FAILED                     0

typedef  uint32_t DaemonRandomValue;
DaemonRandomValue GetDaemonRandomValue(void);

@class DaemonState;
@class Listener;

typedef enum DaemonInterfaceState
{
    DaemonInterfaceState_Up = 1,
    DaemonInterfaceState_Down = 0,
    DaemonInterfaceState_Unknown = -1,
} DaemonInterfaceState;

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
    NSTimeInterval  _timeout;
    NSString        *startAction;
    NSString        *stopAction;
    NSString        *pidFile;
    NSString        *activateInterfaceCommand;
    NSString        *deactivateInterfaceCommand;
    NSTimeInterval  intervallDelay; /* how often do we get local heartbeat */
    NSDate          *lastChecked;
    NSDate          *activatedAt;
    NSDate          *deactivatedAt;
    NSDate          *startedAt;
    NSDate          *stoppedAt;
    DaemonRandomValue _randVal;
    DaemonInterfaceState            _interfaceState;
    
    BOOL _remoteIsFailed;
    BOOL _localIsFailed;
    
    BOOL _localStopActionRequested;
    BOOL _localStartActionRequested;
    
    NSDate          *_lastRx;
    NSDate          *_lastLocalRx;
    NSTimeInterval _goingHotTimeout;
    NSTimeInterval _goingStandbyTimeout;
    
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
@property (readwrite,assign) NSTimeInterval  intervallDelay;
@property (readwrite,assign,atomic) DaemonRandomValue  randVal;
@property (readwrite,assign,atomic) DaemonInterfaceState interfaceState;

@property (readwrite,assign,atomic) BOOL remoteIsFailed;
@property (readwrite,assign,atomic) BOOL localIsFailed;

@property (readwrite,assign,atomic) BOOL localStopActionRequested;
@property (readwrite,assign,atomic) BOOL localStartActionRequested;
@property (readwrite,assign,atomic) NSTimeInterval goingHotTimeout;
@property (readwrite,assign,atomic) NSTimeInterval goingStandbyTimeout;



- (void)eventReceived:(NSString *)event dict:(NSDictionary *)dict;
- (void)eventTimer;

- (void)actionStart;

- (void)actionSendUnknown;
- (void)actionSendFailed;
- (void)actionSendFailover;
- (void)actionSendHot;
- (void)actionSendStandby;
- (void)actionSendTakeoverRequest;
- (void)actionSendTakeoverRequestForced;
- (void)actionSendTakeoverReject;
- (void)actionSendTakeoverConfirm;
- (void)actionSendTransitingToHot;
- (void)actionSendTransitingToStandby;

- (void)sendStatus:(NSString *)status;

- (void)checkForTimeouts;
- (NSDictionary *)status;
- (void)eventForceFailover;
- (void)eventForceTakeover;


- (int)callDeactivateInterface;
- (int)callActivateInterface;
- (int)callStopAction;
- (int)callStartAction;
- (int)executeScript:(NSString *)command;
- (void)checkIfUp;


@end
