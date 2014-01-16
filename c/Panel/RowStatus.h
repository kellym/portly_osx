//
//  RowStatus.h
//  Popup
//
//  Created by Kelly Martin on 9/11/13.
//
//

#import <Cocoa/Cocoa.h>

@interface RowStatus : NSView {
    NSString *title;
    NSTextField *titleField;
    BOOL isActive;
    BOOL isOnline;
}
- (id)initWithFrame:(NSRect)frame;
- (void)setOnline;
- (void)setOffline;
- (void)setActive;
- (void)setInactive;
- (void)toggleState;
- (void)toggleActiveState;
- (void)setTitleAutomatically;
- (void) refresh:(id)sender;

@property(nonatomic, retain) NSString *title;
@property(nonatomic, retain) NSTextField *titleField;
@property(nonatomic) BOOL isOnline;
@property(nonatomic) BOOL isActive;

@end
