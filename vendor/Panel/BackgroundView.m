#import "BackgroundView.h"

#define FILL_OPACITY 1.f
#define STROKE_OPACITY 1.0f

#define LINE_THICKNESS 1.0f
#define CORNER_RADIUS 6.0f

#define SEARCH_INSET 10.0f

#pragma mark -

@implementation BackgroundView

@synthesize arrowX = _arrowX;
@synthesize isAnimating;
@synthesize panel;

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{

    isAnimating = true;
    NSRect contentRect = NSInsetRect([self bounds], LINE_THICKNESS, LINE_THICKNESS);
    NSBezierPath *path = [NSBezierPath bezierPath];

    [path moveToPoint:NSMakePoint(_arrowX, NSMaxY(contentRect))];
    [path lineToPoint:NSMakePoint(_arrowX + ARROW_WIDTH / 2, NSMaxY(contentRect) - ARROW_HEIGHT)];
    [path lineToPoint:NSMakePoint(NSMaxX(contentRect) - CORNER_RADIUS, NSMaxY(contentRect) - ARROW_HEIGHT)];

    NSPoint topRightCorner = NSMakePoint(NSMaxX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT);
    [path curveToPoint:NSMakePoint(NSMaxX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT - CORNER_RADIUS)
         controlPoint1:topRightCorner controlPoint2:topRightCorner];

    [path lineToPoint:NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect) + CORNER_RADIUS)];

    NSPoint bottomRightCorner = NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect));
    [path curveToPoint:NSMakePoint(NSMaxX(contentRect) - CORNER_RADIUS, NSMinY(contentRect))
         controlPoint1:bottomRightCorner controlPoint2:bottomRightCorner];

    [path lineToPoint:NSMakePoint(NSMinX(contentRect) + CORNER_RADIUS, NSMinY(contentRect))];

    [path curveToPoint:NSMakePoint(NSMinX(contentRect), NSMinY(contentRect) + CORNER_RADIUS)
         controlPoint1:contentRect.origin controlPoint2:contentRect.origin];

    [path lineToPoint:NSMakePoint(NSMinX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT - CORNER_RADIUS)];

    NSPoint topLeftCorner = NSMakePoint(NSMinX(contentRect), NSMaxY(contentRect) - ARROW_HEIGHT);
    [path curveToPoint:NSMakePoint(NSMinX(contentRect) + CORNER_RADIUS, NSMaxY(contentRect) - ARROW_HEIGHT)
         controlPoint1:topLeftCorner controlPoint2:topLeftCorner];

    [path lineToPoint:NSMakePoint(_arrowX - ARROW_WIDTH / 2, NSMaxY(contentRect) - ARROW_HEIGHT)];
    [path closePath];


    //[[NSColor colorWithDeviceWhite:0.97f alpha:FILL_OPACITY] setFill];

    float amount = 0.1f * ((float)376 / (float)panel.frame.size.height);
    [[[[NSGradient alloc]
      initWithColorsAndLocations:
      [NSColor colorWithDeviceWhite:1.f alpha:FILL_OPACITY], 0.f,
      [NSColor colorWithDeviceWhite:0.92f alpha:FILL_OPACITY], amount,
      [NSColor colorWithDeviceWhite:1.f alpha:FILL_OPACITY], 1.0f - amount,
      [NSColor colorWithDeviceWhite:.92f alpha:FILL_OPACITY], 1.f,
      nil] autorelease] drawInBezierPath: path angle: 270];
    //[path fill];

    [NSGraphicsContext saveGraphicsState];

    NSBezierPath *clip = [NSBezierPath bezierPathWithRect:[self bounds]];
    [clip appendBezierPath:path];
    [clip addClip];

    [path setLineWidth:LINE_THICKNESS * 2];
    [[NSColor whiteColor] setStroke];
    [path stroke];
    [path setLineWidth:LINE_THICKNESS];

    [NSGraphicsContext restoreGraphicsState];
    NSColor *lineColor = [NSColor colorWithCalibratedRed:185/255.0f green:185/255.0f blue:185/255.0f alpha:1.0f];
    NSPoint point1 = NSMakePoint(NSMinX([self bounds]), 29);
    NSPoint point2 = NSMakePoint(NSMaxX([self bounds]), 29);
    NSPoint point3 = NSMakePoint(NSMinX([self bounds]), NSMaxY([self bounds]) - 46);
    NSPoint point4 = NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]) - 46);
    [lineColor set];
    [NSBezierPath strokeLineFromPoint:point1 toPoint:point2];
    [NSBezierPath strokeLineFromPoint:point3 toPoint:point4];
    isAnimating = false;
}

#pragma mark -
#pragma mark Public accessors

- (void)setArrowX:(NSInteger)value
{
    _arrowX = value;
    [self setNeedsDisplay:YES];
}

@end
