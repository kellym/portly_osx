#import "BackgroundView.h"
#import "ColorGradientView.h"
#import "Row.h"
#import "SettingsView.h"
#import "StatusItemView.h"
#import "UrlView.h"
#import "Button.h"

#define STATUS_ITEM_VIEW_WIDTH 24.0
@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate>
{
    BOOL _hasActivePanel;
    __unsafe_unretained BackgroundView *_backgroundView;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
    NSString *title;
    NSTextField *titleField;
    NSTextField *headerField;
    NSImageView *logo;
    UrlView *getportly;
    SettingsView *settingsView;
    NSMenu *statusMenu;
    NSMutableArray *rows;
    NSString * header;
    ColorGradientView * blankSlateView;
    ColorGradientView *baseBackgroundView;
    ColorGradientView *whiteGradientView;
    ColorGradientView *otherWhiteGradientView;
    Button * blankSlate;
    BOOL shouldShowBlankSlate;
    BOOL isAnimating;
}

@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;

@property (nonatomic, retain) SettingsView *settingsView;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *header;
@property (nonatomic, unsafe_unretained) NSMutableArray *rows;
@property (nonatomic, retain) NSMenu *statusMenu;
@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (void) showBlankSlate;
- (void) hideBlankSlate;
- (void) linkClicked: (id) sender;
- (void)removeRowView:(id)sender;
- (void)showSettings:(id)sender;
- (BOOL) isAnimating;
- (void)defineStatusMenu:(NSMenu *)menu;
- (void)triggerActivePanel:(BOOL)flag;
- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (Row *)addRowWithDelegate:(NSResponder *)delegate;
- (void)openPanel;
- (void)closePanel;

@end
