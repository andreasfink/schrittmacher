//
//  DaemonRandomValue.m
//  schrittmacher
//
//  Created by Andreas Fink on 21/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "DaemonRandomValue.h"


DaemonRandomValue GetDaemonRandomValue(void)
{
    return (DaemonRandomValue)arc4random();
}
