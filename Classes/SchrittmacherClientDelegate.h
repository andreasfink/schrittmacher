//
//  SchrittmacherClientDelegate.h
//  schrittmacher
//
//  Created by Andreas Fink on 26/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <ulib/ulib.h>

@protocol SchrittmacherClientDelegate <NSObject>

- (void)schrittmacherStandbyOrder;
- (void)schrittmacherHotOrder;
- (BOOL)schrittmacherInStandbyMode;

@end
