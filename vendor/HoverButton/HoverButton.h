//
//  HoverButton.h
//  HoverButton
//

#import <Cocoa/Cocoa.h>


@interface HoverButton : NSButton
{
	NSTrackingArea *trackingArea;
    NSString *defaultImage;
    NSString *hoverImage;
}

@end
