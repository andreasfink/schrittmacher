//
//  NSString+urlencode
//  schrittmacher
//
//  Created by Andreas Fink on 26/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import "NSString+urlencode.h"

@implementation NSString(urlencode)

- (NSString *) urlencode
{
    NSArray *escapeChars = [NSArray arrayWithObjects:
                            @";"    , @"/"   , @"?"   , @":"   , @"@"   , @"&"   ,
                            @"="    , @"+"   , @"$"   , @","   , @"["   , @"]"   ,
                            @"#"    , @"!"   , @"'"   , @"("   , @")"   , @"*"   ,
                            @" "	, NULL];
    
    NSArray *replaceChars = [NSArray arrayWithObjects:
                             @"%3B" , @"%2F" , @"%3F" , @"%3A" , @"%40" , @"%26" ,
                             @"%3D" , @"%2B" , @"%24" , @"%2C" , @"%5B" , @"%5D" ,
                             @"%23" , @"%21" , @"%27" ,	 @"%28", @"%29" , @"%2A" ,
                             @"+"   , NULL];
    
    NSUInteger len = [escapeChars count];
    
    NSMutableString *temp =  [[ self stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding ] mutableCopy ];
    
    NSUInteger i;
    for(i = 0; i < len; i++)
    {
        
        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
                              withString: [replaceChars objectAtIndex:i]
                                 options: NSLiteralSearch
                                   range: NSMakeRange(0, [temp length])];
    }
    
    NSString *out = [NSString stringWithString: temp];
    
    return out;
}
@end

