//
//  RowStatus.m
//  Popup
//
//  Created by Kelly Martin on 9/11/13.
//
//

#import "RowStatus.h"

@implementation RowStatus

@synthesize isOnline;
@synthesize isActive;

@synthesize titleField;
@synthesize title;
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        title = @"Offline";
        [self setTitleField: NSTextField.alloc.init];
        titleField.stringValue = title;
        titleField.frame = NSMakeRect(0, 0, self.bounds.size.width, (self.bounds.size.height*0.5) +7);
        [titleField setTextColor:[NSColor whiteColor]];
        [titleField setBezeled:NO];
        [titleField setDrawsBackground:NO];
        [titleField setEditable:NO];
        [titleField setSelectable:NO];
        [titleField setFont:[NSFont fontWithName:@"Lucida Grande" size:11]];
        [titleField setAlignment: NSCenterTextAlignment];
        [self addSubview: [self titleField]];
        [self addObserver: self
               forKeyPath: @"title"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
        [self addObserver: self
               forKeyPath: @"isActive"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
        [self addObserver: self
               forKeyPath: @"isOnline"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
        [self addObserver: self
               forKeyPath: @"titleField"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
        isOnline = false;
        isActive = true;
    }

    return self;
}

-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
    //[[self titleField] setStringValue: title];
    //[[self titleField] setNeedsDisplay: YES];
    //[self setNeedsDisplay:YES];
}

- (void) setOnline {
  [self setIsOnline: true];
    [self setTitleAutomatically];
}

- (void) setOffline {
  [self setIsOnline: false];
    [self setTitleAutomatically];
}

- (void) setActive {
  [self setIsActive: true];
    [self setTitleAutomatically];
}
- (void) setInactive {
  [self setIsActive: false];
    [self setTitleAutomatically];
}

- (void) setTitleAutomatically {
  if (isActive == true) {
    if (isOnline) {
      [self setTitle: @"Online"];
    } else {
      [self setTitle: @"Offline"];
    }
  } else {
    [self setTitle: @"Inactive"];
  }
  titleField.stringValue = title;
  [self performSelectorOnMainThread:@selector(refresh:) withObject: nil waitUntilDone: NO];
}

- (void) refresh:(id)sender {
  [titleField display];
  [titleField setHidden: YES];
  [self.subviews makeObjectsPerformSelector:@selector(setNeedsDisplay)];
  [self setNeedsDisplay: YES];
  [titleField setHidden: NO];
}

- (void) toggleState {
    if (isOnline) {
        [self setOffline];
    } else {
        [self setOnline];
    }
}

- (void) toggleActiveState {
    if (isActive) {
        [self setInactive];
    } else {
        [self setActive];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    NSRect rect = NSMakeRect([self bounds].origin.x+3, [self bounds].origin.y+3, [self bounds].size.width-6, [self bounds].size.height-6);

    NSGradient* aGradient;

    if (isOnline) {
      if (isActive) {
        aGradient = [[NSGradient alloc]
                   initWithStartingColor:[NSColor colorWithCalibratedRed:97/255.0f green:191/255.0f blue:116/255.0f alpha:1.0f]
                               endingColor:[NSColor colorWithCalibratedRed:70/255.0f green:181/255.0f blue:92/255.0f alpha:1.0f]];
      } else {
        aGradient = [[NSGradient alloc]
                   initWithStartingColor:[NSColor colorWithCalibratedRed:222/255.0f green:100/255.0f blue:73/255.0f alpha:1.0f]
                               endingColor:[NSColor colorWithCalibratedRed:240/255.0f green:107/255.0f blue:77/255.0f alpha:1.0f]];

      }
      //aGradient = [[NSGradient alloc]
      //             initWithStartingColor:[NSColor colorWithCalibratedRed:186/255.0f green:213/255.0f blue:130/255.0f alpha:1.0f]
      //                         endingColor:[NSColor colorWithCalibratedRed:147/255.0f green:172/255.0f blue:103/255.0f alpha:1.0f]];

    } else {
      if (isActive) {
        aGradient = [[NSGradient alloc]
                           initWithStartingColor:[NSColor grayColor]
                           endingColor:[NSColor colorWithCalibratedWhite:.15f alpha:1.f]]; // ;NSColor blackColor]];
      } else {
        aGradient = [[NSGradient alloc]
          initWithStartingColor:[NSColor colorWithCalibratedWhite:0.6f alpha: 1.f]
                               endingColor:[NSColor colorWithCalibratedWhite: 0.6f alpha: 1.f]];

      }
    }

    NSBezierPath *path2 = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0];
    //[path2 addClip];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithCalibratedWhite:.0f alpha:.15f]];
    [shadow setShadowBlurRadius:1.5f];
    [shadow setShadowOffset:NSMakeSize(3.f, -2.f)];
    [shadow set];

    [[NSColor blackColor] set];
    [path2 fill];
    //NSRectFill(rect);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4.0 yRadius:4.0];
    [path addClip];
    [aGradient drawInRect:self.bounds angle:90];
    //[path2 fill];
    [aGradient release];
    [shadow release];
    [super drawRect:self.bounds];
}

@end
