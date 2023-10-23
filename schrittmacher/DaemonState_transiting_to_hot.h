//
//  DaemonState_transiting_to_hot.h
//  schrittmacher
//
//  Created by Andreas Fink on 23.01.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "DaemonState.h"

@interface DaemonState_transiting_to_hot : DaemonState
{
    NSDate *_goingHotStartTime;
}
@end

