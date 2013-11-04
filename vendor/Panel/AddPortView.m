#import "AddPortView.h"

@implementation AddPortView

- (id)initWithFrame:(NSRect)frameRect delegate:(NSResponder *)delegateObject
{
  self = [super initWithFrame:frameRect];
  if (self) {
      NSImage *newImage = [NSImage imageNamed: @"add"];
      [newImage setTemplate: NO];
      [self setImage:newImage];
      delegate = delegateObject;
  }

  return self;
}

-(void)mouseDown:(NSEvent *)theEvent {
    if (delegate && [ delegate respondsToSelector:@selector(addTunnel:)]){
        [delegate tryToPerform:@selector(addTunnel:) with: theEvent];
    }
}

@end
