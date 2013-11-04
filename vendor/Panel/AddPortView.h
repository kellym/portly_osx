#import <Cocoa/Cocoa.h>

@interface AddPortView : NSImageView {
  NSResponder *delegate;
}
- (id)initWithFrame:(NSRect)frame delegate:(NSResponder *)delegateObject;
@end

