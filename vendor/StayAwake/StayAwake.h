#import <IOKit/pwr_mgt/IOPMLib.h>

@interface StayAwake : NSObject {
  IOPMAssertionID _assertionID;
}

-(id)init;
-(bool) start;
-(void) stop;

@end
