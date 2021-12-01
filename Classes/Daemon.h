//
//  Daemon.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import "SchrittmacherMetrics.h"

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
#define MESSAGE_LOCAL_REQUEST_FAILOVER      @"LRFO"
#define MESSAGE_LOCAL_REQUEST_TAKEOVER      @"LRTO"

#define GOTO_HOT_SUCCESS                    1
#define GOTO_HOT_ALREADY_HOT                2
#define GOTO_HOT_FAILED                     0

typedef  uint32_t DaemonRandomValue;
DaemonRandomValue GetDaemonRandomValue(void);

@class DaemonState;
@class ListenerPeer4;
@class ListenerPeer6;

typedef enum DaemonInterfaceState
{
    DaemonInterfaceState_Up = 1,
    DaemonInterfaceState_Down = 0,
    DaemonInterfaceState_Unknown = -1,
} DaemonInterfaceState;

@interface Daemon : UMObject
{
    DaemonState     *_currentState;
    NSString        *_lastRemoteMessage;
    NSString        *_lastLocalMessage;
    NSString        *_lastLocalReason;
    NSString        *_lastRemoteReason;
    NSString        *_resourceId;
    int             _localPriority;
    BOOL            _iAmHot;
    NSString        *_remoteAddress;
    NSString        *_localAddress4;
    NSString        *_localAddress6;
    NSString        *_sharedAddress;
    NSString        *_netmask;
    int             _remotePort;
    ListenerPeer4   *_listener4;
    ListenerPeer6   *_listener6;
    NSTimeInterval  _timeout;
    NSString        *_startAction;
    NSString        *_stopAction;
    NSString        *_pidFile;
    long            _pid;
    NSString        *_activateInterfaceCommand;
    NSString        *_deactivateInterfaceCommand;
    NSTimeInterval  _intervallDelay; /* how often do we get local heartbeat */
    NSDate          *_lastChecked;
    NSDate          *_activatedAt;
    NSDate          *_deactivatedAt;
    NSDate          *_startedAt;
    NSDate          *_stoppedAt;
    DaemonRandomValue               _randVal;
    DaemonInterfaceState            _interfaceState;
    
    BOOL            _remoteIsFailed;
    BOOL            _localIsFailed;
    
    BOOL            _localStopActionRequested;
    BOOL            _localStartActionRequested;
    
    NSDate          *_lastRemoteRx;
    NSDate          *_lastLocalRx;
    NSTimeInterval  _goingHotTimeout;
    NSTimeInterval  _goingStandbyTimeout;
    NSDate          *_lastHotSent;
    NSDate          *_lastStandbySent;
    
    UMTimer         *_heartbeatTimer;
    UMLogLevel      _logLevel;
    int             _outstandingRemoteHeartbeats;
    int             _outstandingLocalHeartbeats;
    long            _adminweb_port;
    SchrittmacherMetrics    *_prometheusMetrics;
    UMMutex         *_daemonLock;
    
    UMMutex         *_startActionRunning;
    UMMutex         *_stopActionRunning;
    UMMutex         *_activateInterfaceRunning;
    UMMutex         *_deactivateInterfaceRunning;
}

@property (readwrite,strong) DaemonState *currentState;


@property (readwrite,assign) int        localPriority;
@property (readwrite,strong) NSString   *resourceId;
@property (readwrite,strong) NSString   *remoteAddress;
@property (readwrite,strong) NSString   *localAddress4;
@property (readwrite,strong) NSString   *localAddress6;
@property (readwrite,strong) NSString   *netmask;
@property (readwrite,strong) NSString   *sharedAddress;
@property (readwrite,assign) int        remotePort;

@property (readwrite,strong) ListenerPeer4        *listener4;
@property (readwrite,strong) ListenerPeer6        *listener6;
@property (readwrite,assign,atomic) NSTimeInterval  timeout;
@property (readwrite,strong,atomic) NSDate      *lastRemoteRx;
@property (readwrite,strong,atomic) NSDate      *lastLocalRx;
@property (readwrite,strong,atomic) NSString    *startAction;
@property (readwrite,strong,atomic) NSString    *stopAction;
@property (readwrite,strong,atomic) NSString    *pidFile;

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
@property (readwrite,strong) NSString        *lastRemoteMessage;
@property (readwrite,strong) NSString        *lastLocalMessage;
@property (readwrite,strong) NSString        *lastLocalReason;
@property (readwrite,strong) NSString        *lastRemoteReason;

@property (readwrite,strong) NSDate          *lastHotSent;
@property (readwrite,strong) NSDate          *lastStandbySent;

@property (readwrite,strong) UMTimer         *heartbeatTimer;
@property(readwrite,assign) UMLogLevel logLevel;
@property(readwrite,assign) long pid;
@property(readwrite,assign) long adminweb_port;
@property(readwrite,strong,atomic) SchrittmacherMetrics *prometheusMetrics;
@property(readwrite,strong,atomic) UMMutex  *startActionRunning;
@property(readwrite,strong,atomic) UMMutex  *stopActionRunning;
@property(readwrite,strong,atomic) UMMutex  *activateInterfaceRunning;
@property(readwrite,strong,atomic) UMMutex  *deactivateInterfaceRunning;


- (void)eventReceived:(NSString *)event dict:(NSDictionary *)dict;
- (void)eventHeartbeat;

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


- (void)callDeactivateInterface;
- (void)callActivateInterface;
- (void)callStopAction;
- (void)callStartAction;
- (int)executeScript:(NSString *)command;

@end
