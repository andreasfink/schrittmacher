//
//  libschrittmacherTests.m
//  libschrittmacherTests
//
//  Created by Andreas Fink on 26/05/15.
//  Copyright (c) 2015 SMSRelay AG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "SchrittmacherClient.h"

@interface libschrittmacherTests : XCTestCase
{
    SchrittmacherClient *client;
}
@end

@implementation libschrittmacherTests

- (void)setUp
{
    [super setUp];
    client = [[SchrittmacherClient alloc]init];
    client.port =7700;
    [client start];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    client = NULL;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
