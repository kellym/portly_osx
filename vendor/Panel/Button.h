//
//  Button.h
//  Popup
//
//  Created by Kelly Martin on 9/11/13.
//
//

#import <Cocoa/Cocoa.h>

@interface Button : NSView {
    NSTrackingArea *trackingArea;    
    NSString *title;
    NSTextField *titleField;
    BOOL isMouseDown;
    NSResponder *delegate;
}
- (id)initWithFrame:(NSRect)frame;

@property(nonatomic, retain) NSResponder *delegate;
@property(nonatomic, retain) NSString *title;
@end
