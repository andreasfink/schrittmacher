//
//  DaemonState_TakeoverRequested.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonState.h"
#import "Daemon.h"

@interface DaemonState_TakeoverRequested : DaemonState
{
    DaemonRandomValue randVal;
    int requestCounter;
}

@end
