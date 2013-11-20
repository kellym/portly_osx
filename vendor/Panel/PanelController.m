#import "PanelController.h"

#define OPEN_DURATION 0.001
#define CLOSE_DURATION .05

#define SEARCH_INSET 17

#define CONTENT_HEIGHT_TOP 40
#define CONTENT_HEIGHT_BOTTOM 46
#define POPUP_HEIGHT 320
#define PANEL_WIDTH 300
#define MENU_ANIMATION_DURATION .1
#define BASE_HEIGHT 82
#define ROW_HEIGHT 60
#define ADD_PORT_PADDING 9

#pragma mark -

@implementation PanelController

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize title;
@synthesize statusMenu;
@synthesize settingsView;
@synthesize rows;
@synthesize isAnimating;

#pragma mark -

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
        statusMenu = [[NSMenu alloc] init];
        rows = NSMutableArray.alloc.init;
        header = NSAttributedString.alloc.init;
    }
    return self;
}

//- (void)dealloc
//{
//
//}

#pragma mark -

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.backgroundView setPanel: [self window]];

    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];

    // Resize panel
    NSRect panelRect = [[self window] frame];
    int height = BASE_HEIGHT + 60; // 60 for the blank slate
    panelRect.size.height = height;
    [[self window] setFrame:panelRect display:NO];

    // header
    //

    logo = [[NSImageView alloc] initWithFrame: NSMakeRect( 10, height - CONTENT_HEIGHT_BOTTOM + 7 , 22, 22)];
    [logo setImage: [NSImage imageNamed: @"logo"]];
    [self.window.contentView addSubview: logo];

    headerField = HyperlinkTextField.alloc.init;
    //headerField.frame = NSMakeRect(130,height - CONTENT_HEIGHT_BOTTOM + 3,140,23);
    headerField.frame = NSMakeRect(10,4,150,20);
    headerField.stringValue = header;
    //[headerField setAlignment: NSRightTextAlignment];
    [headerField setTextColor:[NSColor colorWithDeviceWhite:0.4f alpha:1.0f]];
    [headerField setBezeled:NO];
    [headerField setDrawsBackground:NO];
    [headerField setEditable:NO];
    [headerField setSelectable:NO];
    [headerField setFont:[NSFont fontWithName:@"Lucida Grande" size:11]]; //[NSFont boldSystemFontOfSize:11]];
    [self.window.contentView addSubview: headerField];

    addPortView = [ [ AddPortView alloc] initWithFrame: NSMakeRect(PANEL_WIDTH - 20 - ADD_PORT_PADDING, height - CONTENT_HEIGHT_BOTTOM + ADD_PORT_PADDING, 20, 20) delegate:self];
    [self.window.contentView addSubview: addPortView];
    [addPortView setHidden:YES];

    // link to getportly
    getportly = [[ UrlView alloc ] initWithFrame: NSMakeRect(35,height - CONTENT_HEIGHT_BOTTOM + 3, 90, 23) title: @"getportly.com" url: @"https://getportly.com" delegate: self];
    //[getportly setAlignment: NSRightTextAlignment];
    [self.window.contentView addSubview: getportly];

    // Add a title

    title = @"State: Disconnected";

    titleField = NSTextField.alloc.init;
    titleField.frame = NSMakeRect(10,2,150,20);
    titleField.stringValue = title;
    //[titleField setAlignment: NSCenterTextAlignment];
    [titleField setTextColor:[NSColor colorWithDeviceWhite:0.15f alpha:1.0f]];
    [titleField setBezeled:NO];
    [titleField setDrawsBackground:NO];
    [titleField setEditable:NO];
    [titleField setSelectable:NO];
    [titleField setFont:[NSFont fontWithName:@"Lucida Grande" size:11]];
    //[self.window.contentView addSubview: titleField];

    settingsView = [ [ SettingsView alloc] initWithFrame: NSMakeRect(PANEL_WIDTH - 24 - 5, 5, 24, 24) delegate:self];
    [self.window.contentView addSubview: settingsView];

    blankSlateView = [[ColorGradientView alloc] initWithFrame: NSMakeRect(0, CONTENT_HEIGHT_TOP - 4, PANEL_WIDTH, 60)];

        baseBackgroundView = ColorGradientView.alloc.init;
        baseBackgroundView.frame = [blankSlateView bounds];
        [baseBackgroundView setStartingColor: [NSColor colorWithCalibratedWhite: 0.f alpha: 0.05f]];
        [baseBackgroundView setEndingColor: [NSColor colorWithCalibratedWhite: 0.f alpha: 0.0f]];
        [baseBackgroundView setAngle: 270];
        [baseBackgroundView setLocation: 0.1];
        whiteGradientView = ColorGradientView.alloc.init;
        whiteGradientView.frame = NSMakeRect(PANEL_WIDTH-90, 0, 90, ROW_HEIGHT-1);
        [whiteGradientView setStartingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:0.0f]];
        [whiteGradientView setEndingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f]];

        otherWhiteGradientView = ColorGradientView.alloc.init;
        otherWhiteGradientView.frame = NSMakeRect(0, 0, 90, ROW_HEIGHT-1);
        [otherWhiteGradientView setStartingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:0.0f]];
        [otherWhiteGradientView setEndingColor:[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f]];
        [otherWhiteGradientView setAngle: 180];

    blankSlate = [[Button alloc] initWithFrame:NSMakeRect(PANEL_WIDTH - 170, 15, 150, 28)];
    blankSlate.title = @"Add your first port";
    [blankSlate setDelegate: self];
    [blankSlate setHidden: YES];
    arrowView = [[NSImageView alloc] initWithFrame:NSMakeRect( PANEL_WIDTH - 37, 20, 24, 24)];
    [arrowView setImage:[NSImage imageNamed: @"arrow"]];
    [arrowView setHidden: YES];

    arrowTextField = NSTextField.alloc.init;
    arrowTextField.frame = NSMakeRect(PANEL_WIDTH - 237, 16, 200, 20);
    arrowTextField.stringValue = @"Add your first port";
    [arrowTextField setHidden: YES];
    [arrowTextField setAlignment: NSRightTextAlignment];
    [arrowTextField setTextColor:[NSColor colorWithDeviceWhite:0.4f alpha:1.0f]];
    [arrowTextField setBezeled:NO];
    [arrowTextField setDrawsBackground:NO];
    [arrowTextField setEditable:NO];
    [arrowTextField setSelectable:NO];
    [arrowTextField setFont:[NSFont fontWithName:@"Lucida Grande" size:13]];

    blankSlateView.subviews = [NSArray arrayWithObjects:
      baseBackgroundView,
      whiteGradientView,
      otherWhiteGradientView,
      arrowView,
      arrowTextField,
      //blankSlate,
      nil];

    shouldShowBlankSlate = true;
    [self.window.contentView addSubview: blankSlateView];

        [self addObserver: self
               forKeyPath: @"title"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];

        [self addObserver: self
               forKeyPath: @"header"
                  options: NSKeyValueObservingOptionNew
                  context: NULL];
}

- (void) showAddButton
{
  [addPortView setHidden: NO];
  [arrowView setHidden: NO];
  [arrowTextField setHidden: NO];
}

- (void) hideAddButton
{
  [addPortView setHidden: YES];
  [arrowView setHidden: YES];
  [arrowTextField setHidden: YES];
}
- (void) showBlankSlate
{
  [self showAddButton];
  if ([rows count] == 0) {
    [blankSlate setHidden: NO];
     [self.window.contentView setNeedsDisplay: YES];
  }

}

- (void) hideBlankSlate
{
  [self hideAddButton];
  [blankSlate setHidden: YES];
}

- (void) buttonClicked: (id) sender {
  if (sender == blankSlate) {
    [[self delegate] addTunnel: (id)sender];
  }
}

- (void) linkClicked: (id) sender {
  [self setHasActivePanel: NO];
}

- (Row *)addRowWithDelegate:(NSResponder *)delegateObject
{
    // Resize panel
    NSRect statusRect = [self statusRectForWindow:[self window]];
    NSRect panelRect = [[self window] frame];
    NSRect headerRect = [addPortView frame];
    NSRect logoRect = [logo frame];
    NSRect urlRect = [getportly frame];
    //panelRect.origin.y = panelRect.origin.y - 60;
    if ([rows count] > 0) {
      panelRect.size.height = BASE_HEIGHT + (60 * ([rows count]+1));
      panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
      headerRect.origin.y = panelRect.size.height - CONTENT_HEIGHT_BOTTOM + ADD_PORT_PADDING; //headerRect.origin.y + 60;
      logoRect.origin.y = panelRect.size.height - CONTENT_HEIGHT_BOTTOM + 7; //logoRect.origin.y + 60;
      urlRect.origin.y = panelRect.size.height - CONTENT_HEIGHT_BOTTOM + 3; // urlRect.origin.y + 60;
    }
   // else {
   //   [blankSlate setHidden:YES];
   // }
    [ addPortView setFrame:headerRect ];
    [ addPortView setNeedsDisplay: YES];
    [ logo setFrame: logoRect ];
    [ logo setNeedsDisplay: YES];
    [ getportly setFrame:urlRect ];
    [ getportly setNeedsDisplay: YES];
    [[self window] setFrame:panelRect display:YES];

    Row *view = [[Row alloc] initWithFrame:NSMakeRect(0, panelRect.size.height - 60 - CONTENT_HEIGHT_BOTTOM, PANEL_WIDTH, 60) delegate: delegateObject parent: self];
   [view setWantsLayer:YES];
   [self.window.contentView addSubview:view];
   [self.backgroundView setNeedsDisplay: YES];
   [rows addObject:view];
   return [ view autorelease];
}

- (void) removeRowView:(id)sender {
   [rows removeObject:sender];
    NSRect statusRect = [self statusRectForWindow:[self window]];
    NSRect panelRect = [[self window] frame];
    NSRect headerRect = [addPortView frame];
    NSRect logoRect = [logo frame];
    NSRect urlRect = [getportly frame];

    NSInteger count = [rows count];
    if (count == 0) {
      [blankSlate setHidden: NO];
      panelRect.size.height = BASE_HEIGHT + 60;
      panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    } else {
      panelRect.size.height = BASE_HEIGHT + (60 * count);
      for (int i = 0; i < count; i++) {
        Row *r = [rows objectAtIndex: i];
        NSRect frame = NSMakeRect(0, panelRect.size.height - (60 * (i +1)) - CONTENT_HEIGHT_BOTTOM, PANEL_WIDTH, 60);
        [r setFrame: frame];
      }
      panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    }
    //headerRect.origin.y = panelRect.size.height - CONTENT_HEIGHT_BOTTOM + 3; //headerRect.origin.y + 60;
    logoRect.origin.y = panelRect.size.height - CONTENT_HEIGHT_BOTTOM + 7; //logoRect.origin.y + 60;
    urlRect.origin.y = panelRect.size.height - CONTENT_HEIGHT_BOTTOM + 3; // urlRect.origin.y + 60;
    //headerRect.origin.y = headerRect.origin.y - 60;
    headerRect.origin.y = panelRect.size.height - CONTENT_HEIGHT_BOTTOM + ADD_PORT_PADDING; //headerRect.origin.y + 60;
    //urlRect.origin.y = urlRect.origin.y - 60;
    //logoRect.origin.y = logoRect.origin.y - 60;
    [[self window] setFrame:panelRect display:YES];
    [ addPortView setFrame:headerRect ];
    [ addPortView setNeedsDisplay: YES];
    [ logo setFrame: logoRect ];
    [ logo setNeedsDisplay: YES];
    [ getportly setFrame:urlRect ];
    [ getportly setNeedsDisplay: YES];
   [self.backgroundView setNeedsDisplay: YES];
}

-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
  if (keyPath == @"title") {
    titleField.stringValue = title;
  } else if (keyPath == @"header") {
    headerField.stringValue = header;
  }
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;

        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

- (void) setHeader: (NSAttributedString *) value
{

  if ( header != nil) {
    [header release];
  }
  header = [[NSAttributedString alloc] initWithString: value];
  if ( headerField != nil) {
    headerField.attributedStringValue = value;
  }
}

- (BOOL) isAnimating
{
  return [self.backgroundView isAnimating];
}

-(void)defineStatusMenu:(NSMenu *)menu
{
  statusMenu = menu;
}
- (void)showSettings:(NSEvent *)theEvent {
  [NSMenu popUpContextMenu:statusMenu withEvent:theEvent forView:[[self window] contentView]];
}

- (void)addTunnel:(NSEvent *)theEvent {
  [self setHasActivePanel: NO];
  dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
    [[self delegate] addTunnel: (id)theEvent];
  });
}

- (void)triggerActivePanel:(BOOL)flag
{
  [self setHasActivePanel: flag];
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];

    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);

    self.backgroundView.arrowX = panelX;

}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;

    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }

    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
    NSWindow *panel = [self window];

    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];

    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);

    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);

    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    //statusRect.size.width = PANEL_WIDTH;
    [panel setFrame:panelRect display:YES];
    [panel makeKeyAndOrderFront:nil];

    NSTimeInterval openDuration = OPEN_DURATION;

    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);

    self.backgroundView.arrowX = panelX;

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.001];
    [[panel animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];

    [self.window.contentView setNeedsDisplay: YES];
    [innerPool release];
}

- (void)closePanel
{
    NSAutoreleasePool *innerPool = [NSAutoreleasePool new];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];

    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{

        [self.window orderOut:nil];
    });
    [innerPool release];
}

@end
