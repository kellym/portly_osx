//
//  Button.m
//  Popup
//
//  Created by Kelly Martin on 9/11/13.
//
//

#import "Button.h"

@implementation Button

@synthesize delegate;
@synthesize title;
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        title = @"Start";
        titleField = NSTextField.alloc.init;
        titleField.stringValue = title;
        titleField.frame = NSMakeRect(0, 0, self.bounds.size.width, (self.bounds.size.height*0.5) +7);
        [titleField setTextColor:[NSColor blackColor]];
        [titleField setBezeled:NO];
        [titleField setDrawsBackground:NO];
        [titleField setEditable:NO];
        [titleField setSelectable:NO];
        [titleField setFont:[NSFont fontWithName:@"Lucida Grande" size:11]];
        [titleField setAlignment: NSCenterTextAlignment];
        [self addSubview:titleField];
        [self addObserver: self
               forKeyPath: @"title"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
        isMouseDown = false;
    }

    return self;
}

-(void)mouseDown:(NSEvent *)theEvent {
    isMouseDown = true;
    [self setNeedsDisplay:true];
}

-(void)mouseUp:(NSEvent *)theEvent {
    isMouseDown = false;
    [self setNeedsDisplay:true];
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(buttonClicked:)]){
        [[self delegate] tryToPerform:@selector(buttonClicked:) with:(id)self];
    }
}

-(void)mouseExited:(NSEvent *)theEvent {
    if (isMouseDown) {
        isMouseDown = false;
        [self setNeedsDisplay:true];
    }
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


-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
    //BOOL newValue = [[change objectForKey: NSKeyValueChangeNewKey] boolValue];
    titleField.stringValue = title;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
    NSRect rect = NSMakeRect([self bounds].origin.x+3, [self bounds].origin.y+3, [self bounds].size.width-6, [self bounds].size.height-6);
    if (isMouseDown) {

        NSBezierPath *path = [NSBezierPath
                              bezierPathWithRoundedRect:rect
                              xRadius:4.0f
                              yRadius:4.0f];

        [[NSColor grayColor] setStroke];

        NSShadow *shadow2 = [[[NSShadow alloc] init] autorelease];
        [shadow2 setShadowColor:[NSColor colorWithCalibratedWhite:0.0f
                                                            alpha:0.25f]];
        [shadow2 setShadowBlurRadius:2.0f];
        [shadow2 setShadowOffset:NSMakeSize(0.f, -0.5f)];
        [shadow2 set];
        [path fill];
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0f
                                                           alpha:0.5f]];
        [shadow setShadowBlurRadius:3.0f];
        [shadow set];
        [path addClip];
        [path stroke];
        [shadow release];
        //NSBezierPath *path2 = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4.0 yRadius:4.0];

        //[path2 addClip];


        NSGradient* aGradient = [[NSGradient alloc]
                                 initWithStartingColor:[NSColor colorWithCalibratedRed:228/255.0f green:228/255.0f blue:228/255.0f alpha:1.0f]
                                 endingColor:[NSColor whiteColor]];
        [aGradient drawInRect:rect angle:90];
        [aGradient release];
        [path stroke];

    } else {
    // Drawing code here.

    NSGradient* aGradient = [[NSGradient alloc]
                             initWithStartingColor:[NSColor colorWithCalibratedRed:228/255.0f green:228/255.0f blue:228/255.0f alpha:1.0f]
                             endingColor:[NSColor whiteColor]];
    //[aGradient drawInRect:dirtyRect angle:90];

    NSBezierPath *path2 = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4.0 yRadius:4.0];
    //[path2 addClip];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:2.0f];
    [shadow setShadowOffset:NSMakeSize(0.f, -0.5f)];
    [shadow set];

    [[NSColor controlColor] set];
    [path2 fill];
    //NSRectFill(rect);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4.0 yRadius:4.0];
    [path addClip];
    [aGradient drawInRect:dirtyRect angle:90];
    [aGradient release];
    [shadow release];
    //[path2 fill];
    }

    [super drawRect:dirtyRect];
    [innerPool release];
}

@end
