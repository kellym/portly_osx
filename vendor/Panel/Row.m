//
//  Row.m
//  Popup
//
//  Created by Kelly Martin on 9/10/13.
//
//

#import "Row.h"
#define ROW_WIDTH 300
#define ROW_HEIGHT 60

@implementation Row

@synthesize backgroundColor;
@synthesize inactiveColor;
@synthesize lineColor;
@synthesize hoverColor;
@synthesize disabledHoverColor;
@synthesize title;
@synthesize subtitle;
@synthesize delegate;
@synthesize parent;
@synthesize currentState;
@synthesize activityButton;
@synthesize gradientView;
@synthesize fillGradientView;

- (id)initWithFrame:(NSRect)frame delegate:(NSResponder *)delegateObject parent: (NSObject *)parentObject
{
    self = [super initWithFrame: frame];
    if (self) {
        delegate = delegateObject;
        parent = parentObject;

        self.backgroundColor = [NSColor whiteColor];
        self.hoverColor = [ NSColor colorWithCalibratedRed:207/255.0f green:242/255.0f blue:249/255.0f alpha:1.0f]; // [NSColor colorWithCalibratedRed:220/255.0f green:237/255.0f blue:255/255.0f alpha:1.0f];
        self.disabledHoverColor = [NSColor colorWithCalibratedRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f]; // [NSColor colorWithCalibratedRed:220/255.0f green:237/255.0f blue:255/255.0f alpha:1.0f];

        self.inactiveColor =[NSColor colorWithCalibratedRed:205/255.0f green:205/255.0f blue:205/255.0f alpha:1.0f]; // [NSColor colorWithCalibratedRed:220/255.0f green:237/255.0f blue:255/255.0f alpha:1.0f];

        copyButton = [[Button alloc] initWithFrame:NSMakeRect(ROW_WIDTH - 90, 12, 80, 35)];
        copyButton.title = @"Copy Link";

        NSRect location = NSMakeRect(10, 12, 62, 35);
        activityButton = [[Button alloc] initWithFrame:location];
        currentState = [[RowStatus alloc] initWithFrame:location];

        [self setLineColor: [NSColor colorWithCalibratedRed:226/255.0f green:226/255.0f blue:226/255.0f alpha:1.0f]];
        //[self setBackgroundColor: [NSColor colorWithCalibratedRed:220/255.0f green:237/255.0f blue:255/255.0f alpha:1.0f]];
        [self setBackgroundColor: [self hoverColor]];

        hoverBackgroundView = ColorGradientView.alloc.init;
        hoverBackgroundView.frame = NSMakeRect(0,0,ROW_WIDTH,ROW_HEIGHT-1);
        [hoverBackgroundView setStartingColor: [self backgroundColor]];

        self.fillGradientView = ColorGradientView.alloc.init;
        self.fillGradientView.frame = NSMakeRect(ROW_WIDTH-130, 0, 130, ROW_HEIGHT-1);
        [self.fillGradientView setStartingColor:[self hoverColor]];

        self.gradientView = ColorGradientView.alloc.init;
        self.gradientView.frame = NSMakeRect(100, 0, 70, ROW_HEIGHT-1);
        [self.gradientView setStartingColor:[NSColor colorWithCalibratedRed:207/255.0f green:242/255.0f blue:249/255.0f alpha:0.0f]];
        [self.gradientView setEndingColor:[self hoverColor]];

        titleField = NSTextField.alloc.init;
        titleField.stringValue = @"";
        titleField.frame = NSMakeRect(78, 25, 200, 20);
        [titleField setBezeled:NO];
        [titleField setDrawsBackground:NO];
        [titleField setEditable:NO];
        [titleField setSelectable:NO];
        [[titleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];

        [activityButton setDelegate:self];
        [copyButton setDelegate:self];

        subtitleField = NSTextField.alloc.init;
        subtitleField.stringValue = @"";
        subtitleField.frame = NSMakeRect(76, 9, 200, 20);
        [subtitleField setTextColor:[NSColor grayColor]];
        [subtitleField setBezeled:NO];
        [subtitleField setDrawsBackground:NO];
        [subtitleField setEditable:NO];
        [subtitleField setSelectable:NO];
        [subtitleField setFont:[NSFont fontWithName:@"Lucida Grande" size:10]];
        [[subtitleField cell] setLineBreakMode:NSLineBreakByTruncatingTail];

        [copyButton setHidden: YES];
        [self.gradientView setHidden:YES];
        [hoverBackgroundView setHidden:YES];
        [self.fillGradientView setHidden:YES];
        [activityButton setHidden:YES];

        self.subviews = [NSArray arrayWithObjects:
            hoverBackgroundView,
            currentState,
            activityButton,
            subtitleField,
            titleField,
            self.fillGradientView,
            self.gradientView,
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
  [self.layer setBackgroundColor: [self hoverColor]];
  [self.fillGradientView setStartingColor:[self hoverColor]];
  [self.gradientView setStartingColor:[NSColor colorWithCalibratedRed:207/255.0f green:242/255.0f blue:249/255.0f alpha:0.0f]];
  [self.gradientView setEndingColor:[self hoverColor]];
  [hoverBackgroundView setStartingColor: [self hoverColor]];
  [self setNeedsDisplay: YES];
  [self.gradientView setNeedsDisplay: YES];
  [hoverBackgroundView setNeedsDisplay: YES];
  [self.fillGradientView setNeedsDisplay: YES];
  if ([currentState isOnline]) {
    [activityButton setTitle:@"Stop"];
  } else {
    [activityButton setTitle:@"Start"];
  }
  [titleField setTextColor:[NSColor blackColor]];
  [subtitleField setTextColor:[NSColor grayColor]];
  [self showActivityButtonIfMouseEntered];
}

- (void) setInactive {
  [self.layer setBackgroundColor: [self disabledHoverColor]];
  [self.fillGradientView setStartingColor:[self disabledHoverColor]];
  [self.gradientView setStartingColor:[NSColor colorWithCalibratedRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:0.0f]];
  [self.gradientView setEndingColor:[self disabledHoverColor]];
  [hoverBackgroundView setStartingColor: [self disabledHoverColor]];
  [self setNeedsDisplay: YES];
  [self.gradientView setNeedsDisplay: YES];
  [hoverBackgroundView setNeedsDisplay: YES];
  [self.fillGradientView setNeedsDisplay: YES];
  [currentState setInactive];
  [activityButton setTitle:@"Cancel"];
  [titleField setTextColor: [self inactiveColor]];
  [subtitleField setTextColor: [self inactiveColor]];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSPoint point1 = NSMakePoint(NSMinX([self bounds]), NSMaxY([self bounds]));
    NSPoint point2 = NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]));
    [[self lineColor] set];
    [[NSColor whiteColor] setFill];
        NSRectFill(dirtyRect);
    [NSBezierPath strokeLineFromPoint:point1 toPoint:point2];

}
-(void)mouseDown:(NSEvent *)theEvent {
}

- (void) mouseEntered:(NSEvent *)theEvent {
  isMouseEntered = true;

  if ([currentState isOnline] || [currentState isActive]) {
    self.layer.backgroundColor = [[self backgroundColor] CGColor];
  } else {
    self.layer.backgroundColor = [[self disabledHoverColor] CGColor];
  }
  [copyButton setHidden: NO];
  [gradientView setHidden:NO];
  [fillGradientView setHidden:NO];
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
