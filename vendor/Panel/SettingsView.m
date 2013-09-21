#import "SettingsView.h"

@implementation SettingsView

- (id)initWithFrame:(NSRect)frameRect delegate:(NSResponder *)delegateObject
{
  self = [super initWithFrame:frameRect];
  if (self) {
      NSImage *newImage = [NSImage imageNamed: @"gear"];
      [newImage setTemplate: YES];
      [self setImage:newImage];
      delegate = delegateObject;
  }

  return self;
}

-(void)mouseDown:(NSEvent *)theEvent {
    if (delegate && [ delegate respondsToSelector:@selector(showSettings:)]){
        [delegate tryToPerform:@selector(showSettings:) with: theEvent];
    }
}

@end
