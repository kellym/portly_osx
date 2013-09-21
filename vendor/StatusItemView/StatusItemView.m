
#import 'StatusItemView.h'



@implementation StatusItemView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        statusItem = nil;
        //title = @"";
        isMenuVisible = NO;
    }
    return self;
}

- (void)dealloc {
    [statusItem release];
    [title release];
    [super dealloc];
}

@synthesize statusItem;

- (void)mouseDown:(NSEvent *)event {
    [[self menu] setDelegate:self];
    [statusItem popUpStatusItemMenu:[self menu]];
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event {
    // Treat right-click just like left-click
    [self mouseDown:event];
}

- (void)menuWillOpen:(NSMenu *)menu {
    isMenuVisible = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    isMenuVisible = NO;
    [menu setDelegate:nil];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
    // Draw status bar background, highlighted if menu is showing
    [statusItem drawStatusBarBackgroundInRect:[self bounds]
                                withHighlight:isMenuVisible];

    // Draw title string
    //NSPoint origin = NSMakePoint(StatusItemViewPaddingWidth,
    //                             StatusItemViewPaddingHeight);
    //[title drawAtPoint:origin
    //    withAttributes:[self titleAttributes]];
}
