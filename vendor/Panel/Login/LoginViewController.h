#import <Cocoa/Cocoa.h>

@interface LoginService
-(void)signIn: (id)sender;
-(void)forgotPassword: (id)sender;
@end

@interface LoginViewController : NSViewController
+(LoginViewController *) sharedController;
-(IBAction)signInClicked: (id)sender;
-(IBAction)forgotPasswordClicked: (id)sender;
-(void) awakeFromNib;

@property IBOutlet NSTextField *email;
@property IBOutlet NSTextField *password;
@property (nonatomic, retain) NSString * error;
@end
