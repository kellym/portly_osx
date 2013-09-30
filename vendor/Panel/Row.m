//
//  Row.m
//  Popup
//
//  Created by Kelly Martin on 9/10/13.
//
//

#import "Row.h"
#define ROW_HEIGHT 60

@implementation Row

@synthesize backgroundColor;
@synthesize lineColor;
@synthesize title;
@synthesize subtitle;
@synthesize delegate;
@synthesize parent;
@synthesize currentState;
@synthesize activityButton;

- (id)initWithFrame:(NSRect)frame delegate:(NSResponder *)delegateObject parent: (NSObject *)parentObject
{
    self = [super initWithFrame: frame];
    if (self) {
        delegate = delegateObject;
        parent = parentObject;

        self.backgroundColor = [NSColor whiteColor];
        hoverColor =[NSColor colorWithCalibratedRed:187/255.0f green:242/255.0f blue:245/255.0f alpha:1.0f]; // [NSColor colorWithCalibratedRed:220/255.0f green:237/255.0f blue:255/255.0f alpha:1.0f];

        copyButton = [[Button alloc] initWithFrame:NSMakeRect(190, 14, 80, 32)];
        copyButton.title = @"Copy Link";

        NSRect location = NSMakeRect(8, 12, 59, 32);
        activityButton = [[Button alloc] initWithFrame:location];
        currentState = [[RowStatus alloc] initWithFrame:location];

        [self setLineColor: [NSColor colorWithCalibratedRed:150/255.0f green:167/255.0f blue:185/255.0f alpha:1.0f]];
        //[self setBackgroundColor: [NSColor colorWithCalibratedRed:220/255.0f green:237/255.0f blue:255/255.0f alpha:1.0f]];
        [self setBackgroundColor: hoverColor];

        baseBackgroundView = ColorGradientView.alloc.init;
        baseBackgroundView.frame = [self bounds];
        [baseBackgroundView setStartingColor: [NSColor colorWithCalibratedWhite: 0.f alpha: 0.05f]];
        [baseBackgroundView setEndingColor: [NSColor colorWithCalibratedWhite: 0.f alpha: 0.0f]];
        [baseBackgroundView setAngle: 270];
        [baseBackgroundView setLocation: 0.1];

        hoverBackgroundView = ColorGradientView.alloc.init;
        hoverBackgroundView.frame = [self bounds];
        [hoverBackgroundView setStartingColor: [self backgroundColor]];
        [hoverBackgroundView setEndingColor: [self backgroundColor]];

        fillGradientView = ColorGradientView.alloc.init;
        fillGradientView.frame = NSMakeRect(170, 0, 110, ROW_HEIGHT-1);
        [fillGradientView setStartingColor:hoverColor];

        whiteGradientView = ColorGradientView.alloc.init;
        whiteGradientView.frame = NSMakeRect(190, 0, 90, ROW_HEIGHT-1);
        [whiteGradientView setStartingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:0.0f]];
        [whiteGradientView setEndingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f]];

        otherWhiteGradientView = ColorGradientView.alloc.init;
        otherWhiteGradientView.frame = NSMakeRect(0, 0, 90, ROW_HEIGHT-1);
        [otherWhiteGradientView setStartingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:0.0f]];
        [otherWhiteGradientView setEndingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f]];
        [otherWhiteGradientView setAngle: 180];

        gradientView = ColorGradientView.alloc.init;
        gradientView.frame = NSMakeRect(100, 0, 70, ROW_HEIGHT-1);
        [gradientView setStartingColor:[NSColor colorWithCalibratedRed:187/255.0f green:242/255.0f blue:245/255.0f alpha:0.0f]];
        [gradientView setEndingColor:hoverColor];

        titleField = NSTextField.alloc.init;
        titleField.stringValue = @"";
        titleField.frame = NSMakeRect(76, 24, 200, 20);
        [titleField setBezeled:NO];
        [titleField setDrawsBackground:NO];
        [titleField setEditable:NO];
        [titleField setSelectable:NO];
        [[titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];

        [activityButton setDelegate:self];
        [copyButton setDelegate:self];

        subtitleField = NSTextField.alloc.init;
        subtitleField.stringValue = @"";
        subtitleField.frame = NSMakeRect(76, 8, 200, 20);
        [subtitleField setTextColor:[NSColor grayColor]];
        [subtitleField setBezeled:NO];
        [subtitleField setDrawsBackground:NO];
        [subtitleField setEditable:NO];
        [subtitleField setSelectable:NO];
        [subtitleField setFont:[NSFont fontWithName:@"Lucida Grande" size:10]];
        [[subtitleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];

        [copyButton setHidden: YES];
        [gradientView setHidden:YES];
        [hoverBackgroundView setHidden:YES];
        [fillGradientView setHidden:YES];
        [activityButton setHidden:YES];

        self.subviews = [NSArray arrayWithObjects:
            baseBackgroundView,
            otherWhiteGradientView,
            hoverBackgroundView,
            currentState,
            activityButton,
            subtitleField,
            titleField,
            whiteGradientView,
            fillGradientView,
            gradientView,
            copyButton,
            nil
        ];

        [self addObserver: self
               forKeyPath: @"title"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];

        [self addObserver: self
               forKeyPath: @"subtitle"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
    }

    return self;
}

- (void) remove
{
  // first we have to remove the observer;

        [self removeObserver: self
               forKeyPath: @"title"
                  context: NULL];

        [self removeObserver: self
               forKeyPath: @"subtitle"
                  context: NULL];
       [self removeFromSuperview ];

    if ([self parent] && [[self parent] respondsToSelector:@selector(removeRowView:)]){
        [[self parent] removeRowView: (id)self ];
    }
//  [self dealloc];
}

-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
  if (keyPath == @"title") {
    titleField.stringValue = title;
  } else if (keyPath == @"subtitle") {
    subtitleField.stringValue = subtitle;
  }
  [self setNeedsDisplay:true];
}

-(void)buttonClicked:(id)sender {
  if (sender == activityButton) {
    [ currentState toggleState ];
    if ([currentState isOnline]) {
        activityButton.title = @"Stop";
    } else {
        activityButton.title = @"Start";
    }
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(toggleState:)]){
        [[self delegate] toggleState: self ];
    }
  } else {
    NSUserNotification *notification = [[[NSUserNotification alloc] init] autorelease];
    notification.title = @"Copied Link";
    notification.informativeText = [NSString stringWithFormat:@"%@%@%@", @"A link to \"", subtitle, @"\" has been copied to your clipboard."];

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(copyLink:)]){
       [[self delegate] copyLink: (id) self];
    }
  }

}

- (void) setOnline {
  [currentState setOnline];
  [activityButton setTitle:@"Stop"];
}

- (void) setOffline {
  [currentState setOffline];
  if ([currentState isActive]) {
    [activityButton setTitle:@"Start"];
  } else {
    [activityButton setHidden: YES];
    [currentState setHidden: NO];
  }
}

- (void) setActive {
  [currentState setActive];
  if ([currentState isOnline]) {
    [activityButton setTitle:@"Stop"];
  } else {
    [activityButton setTitle:@"Start"];
  }
  [self showActivityButtonIfMouseEntered];
}

- (void) setInactive {
  [currentState setInactive];
  [activityButton setTitle:@"Cancel"];
}

- (void)drawRect:(NSRect)dirtyRect
{
    //NSPoint point1 = NSMakePoint(NSMinX([self bounds]), NSMaxY([self bounds]));
    //NSPoint point2 = NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]));
    //[[self lineColor] set];
    [[NSColor whiteColor] setFill];
        NSRectFill(dirtyRect);
    //[NSBezierPath strokeLineFromPoint:point1 toPoint:point2];

}
-(void)mouseDown:(NSEvent *)theEvent {
}

- (void) mouseEntered:(NSEvent *)theEvent {
  isMouseEntered = true;
  self.layer.backgroundColor = [[self backgroundColor] CGColor];
  [copyButton setHidden: NO];
  [gradientView setHidden:NO];
  [fillGradientView setHidden:NO];
  //[otherWhiteGradientView setHidden:YES];
  [hoverBackgroundView setHidden:NO];
  [self showActivityButtonIfMouseEntered];
}

-(void) showActivityButtonIfMouseEntered
{
    if (isMouseEntered && ([currentState isActive] || [currentState isOnline])) {
      [currentState setHidden: YES];
      [activityButton setHidden:NO];
    }
}

-(void)mouseExited:(NSEvent *)theEvent
{
    isMouseEntered = false;
    self.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    [copyButton setHidden: YES];
    [currentState setHidden: NO];
    [gradientView setHidden:YES];
    //[otherWhiteGradientView setHidden:NO];
    [hoverBackgroundView setHidden:YES];
    [fillGradientView setHidden:YES];
        [activityButton setHidden:YES];
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
