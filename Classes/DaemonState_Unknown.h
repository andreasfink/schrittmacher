//
//  DaemonState_Unknown.h
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonState.h"
#import "DaemonRandomValue.h"

@interface DaemonState_Unknown : DaemonState
{
    int unknownCounter;
    DaemonRandomValue  randVal;
    
}

- (DaemonState *)eventStart;

@end
