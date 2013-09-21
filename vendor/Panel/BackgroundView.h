#define ARROW_WIDTH 16
#define ARROW_HEIGHT 8

@interface BackgroundView : NSView
{
    NSInteger _arrowX;
    BOOL isAnimating;
    NSWindow *panel;
}

@property (nonatomic, assign) NSInteger arrowX;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, retain) NSWindow *panel;
@end
