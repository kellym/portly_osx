#import <Cocoa/Cocoa.h>

@interface SettingsView : NSImageView {
  NSResponder *delegate;
}
- (id)initWithFrame:(NSRect)frame delegate:(NSResponder *)delegateObject;
@end
