//
//  ColorGradientView.m
//  Popup
//
//  Created by Kelly Martin on 9/11/13.
//
//

#import "ColorGradientView.h"

@implementation ColorGradientView

// Automatically create accessor methods
@synthesize startingColor;
@synthesize endingColor;
@synthesize location;
@synthesize angle;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self setStartingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f]];
        [self setEndingColor:nil];
        [self setAngle:0];
        [self setLocation: 1.0];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    if (endingColor == nil || [startingColor isEqual:endingColor]) {
        // Fill view with a standard background color
        [startingColor set];
        NSRectFill(rect);
    }
    else {
        // Fill view with a top-down gradient
        // from startingColor to endingColor
        NSGradient* aGradient = [[NSGradient alloc]
                                 initWithColorsAndLocations:startingColor, 0.f,
                                 endingColor, location, nil];
        [aGradient drawInRect:[self bounds] angle:angle];
        [aGradient release];
    }
}

@end
