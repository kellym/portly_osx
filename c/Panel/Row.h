//
//  Row.h
//  Popup
//
//  Created by Kelly Martin on 9/10/13.
//
//
#import "Button.h"
#import "ColorGradientView.h"
#import "RowStatus.h"
#import <Cocoa/Cocoa.h>

@interface Row : NSView {
    BOOL isMouseEntered;
    Button * activityButton;
    Button * copyButton;
    ColorGradientView *hoverBackgroundView;
    ColorGradientView *fillGradientView;
    ColorGradientView *gradientView;
    NSColor *hoverColor;
    NSColor *disabledHoverColor;
    NSColor *inactiveColor;
    NSColor *lineColor;
    NSColor *backgroundColor;
    NSObject *parent;
    NSResponder *delegate;
    NSString *subtitle;
    NSString *title;
    NSTextField *subtitleField;
    NSTextField *titleField;
    NSTrackingArea *trackingArea;
    RowStatus * currentState;
}
- (id)initWithFrame:(NSRect)frame delegate:(NSResponder *)delegateObject parent:(NSObject *)parentObject;
-(void)buttonClicked:(id)sender;
-(void) showActivityButtonIfMouseEntered;
@property(nonatomic, retain) Button * activityButton;
@property(nonatomic, weak) NSObject *parent;
@property(nonatomic, weak) NSResponder *delegate;
@property(nonatomic, retain) NSString *subtitle;
@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) RowStatus * currentState;
@property(nonatomic, retain) NSColor *lineColor;
@property(nonatomic, retain) NSColor *hoverColor;
@property(nonatomic, retain) NSColor *disabledHoverColor;
@property(nonatomic, retain) NSColor *backgroundColor;
@property(nonatomic, retain) NSColor *inactiveColor;
@property(nonatomic, retain) ColorGradientView *fillGradientView;
@property(nonatomic, retain) ColorGradientView *gradientView;

@end
