//
//  ColorGradientView.h
//  Popup
//
//  Created by Kelly Martin on 9/11/13.
//
//

#import <Cocoa/Cocoa.h>

@interface ColorGradientView : NSView
{
    NSColor *startingColor;
    NSColor *endingColor;
    int angle;
    float location;
}

// Define the variables as properties
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(assign) int angle;
@property(assign) float location;

@end
