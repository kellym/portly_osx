//
//  StayAwake.m
//  port
//
//  Created by Kelly Martin on 5/5/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import "StayAwake.h"

@implementation StayAwake

-(id)init {
  self = [super init];
  return self;
}

-(bool) start {
  CFStringRef reasonForActivity = CFSTR("Portly Connection");
  IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep,
                                    kIOPMAssertionLevelOn, reasonForActivity, &_assertionID);

  return success;
}
-(void) stop
{
  IOPMAssertionRelease(_assertionID);
}
@end

