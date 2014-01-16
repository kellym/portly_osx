//
//  HoverButton.m
//  HoverButton
//

#import "HoverButton.h"


@implementation HoverButton

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if (trackingArea)
	{
		[self removeTrackingArea:trackingArea];
		trackingArea = nil;
	}
	
	NSTrackingAreaOptions options = NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow;
	trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:options owner:self userInfo:nil];
	[self addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)event
{
	[self setImage:[NSImage imageNamed: hoverImage]];
}

- (void)mouseExited:(NSEvent *)event
{
	[self setImage:[NSImage imageNamed: defaultImage]];
}

@end
