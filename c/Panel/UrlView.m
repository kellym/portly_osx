//
//  URLView.m
//  Portly
//
//  Created by Kelly Martin on 9/15/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import "UrlView.h"

@implementation UrlView

@synthesize color;
@synthesize hoverColor;

- (id)initWithFrame:(NSRect)frame title:(NSString *)textValue url:(NSString *)urlValue delegate:(NSResponder *) delegateObject
{
    self = [super initWithFrame:frame];
    if (self) {
      delegate = delegateObject;
        [self setBezeled:NO];
        [self setDrawsBackground:NO];
        [self setEditable:NO];
        [self setSelectable:NO];
        [self setStringValue: textValue];
        [self setFont:[NSFont boldSystemFontOfSize:11]];
        url = urlValue;
        [self addObserver: self
               forKeyPath: @"color"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
        [self setColor: [NSColor colorWithCalibratedRed:230/255.0f green:35/255.0f blue:142/255.0f alpha:1.0f]];
        [self setHoverColor: [NSColor colorWithCalibratedRed:239/255.0f green:85/255.0f blue:128/255.0f alpha:1.0f]];
        //[self setHoverColor: [NSColor colorWithCalibratedRed:221/255.0f green:171/255.0f blue:189/255.0f alpha:1.0f]];
    }

    return self;
}

-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
    if (keyPath == @"color") {
        [self setTextColor: color];
    }
}

/*
- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}
*/
- (void) mouseEntered:(NSEvent *)theEvent {
    [self setTextColor: hoverColor];
}

- (void) mouseDown:(NSEvent *)theEvent {
  [ [ NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url] ];
    if (delegate && [delegate respondsToSelector:@selector(linkClicked:)])
    {
        [delegate linkClicked:self];
    }
}

- (void) mouseExited:(NSEvent *)theEvent {
    [self setTextColor:color];
}

-(void)updateTrackingAreas
{
    if(trackingArea != nil) {
        [self removeTrackingArea:trackingArea];
    }

    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
}

@end
