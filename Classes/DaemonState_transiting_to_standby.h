//
//  DaemonState_transiting_to_standby.h
//  schrittmacher
//
//  Created by Andreas Fink on 23.01.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "DaemonState.h"

@interface DaemonState_transiting_to_standby : DaemonState
{
    NSDate *_goingStandbyStartTime;
}
@end
