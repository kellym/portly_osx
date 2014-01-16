#import <Cocoa/Cocoa.h>

@protocol LoginServiceDelegate <NSObject>
@optional
-(void)signIn: (id)sender;
-(void)forgotPassword: (id)sender;
-(void)setController: (NSViewController *) controller;
@end

@interface LoginViewController : NSViewController {
  NSResponder <LoginServiceDelegate> * _delegate;
}
-(void)initWithLoginService:(NSResponder <LoginServiceDelegate> *)delegate;
-(IBAction)signInClicked: (id)sender;
-(IBAction)forgotPasswordClicked: (id)sender;
-(void) awakeFromNib;

@property IBOutlet NSTextField *email;
@property IBOutlet NSTextField *password;
@property (nonatomic, retain) NSString * error;
//@property (nonatomic, retain) NSView * view;
@property (nonatomic, assign) NSWindow * window;
@end
