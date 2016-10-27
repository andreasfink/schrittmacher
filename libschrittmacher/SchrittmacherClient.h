//
//  SchrittmacherClient.h
//  schrittmacher
//
//  Created by Andreas Fink on 26/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <ulib/ulib.h>

#define MESSAGE_LOCAL_HOT           @"LHOT"
#define MESSAGE_LOCAL_STDBY         @"LSBY"
#define MESSAGE_LOCAL_FAIL          @"LFAI"


@interface SchrittmacherClient : UMObject
{
    NSString *resourceId;
    int port;
    int addressType;
    UMSocket *uc;
    UMHost *localHost;
    id delegate;
}
@property(readwrite,strong)NSString *resourceId;

- (void)heartbeat:(BOOL)imHot;
- (void)notifyFailure;

@end
