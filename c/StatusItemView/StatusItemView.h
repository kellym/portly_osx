
#import <Cocoa/Cocoa.h>

@interface StatusItemView : NSView {
    NSStatusItem *statusItem;
    BOOL isMenuVisible;
}

- (id)initWithFrame:(NSRect)frame
- (void)dealloc
- (void)mouseDown:(NSEvent *)event
- (void)rightMouseDown:(NSEvent *)event
- (void)menuWillOpen:(NSMenu *)menu
- (void)menuDidClose:(NSMenu *)menu
- (void)drawRect:(NSRect)rect

@synthesize statusItem;
@property (retain, nonatomic) NSStatusItem *statusItem;
//@property (retain, nonatomic) NSString *image;
@end
