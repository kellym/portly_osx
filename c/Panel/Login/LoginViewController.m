#import "LoginViewController.h"

@implementation LoginViewController

//@synthesize view;
@synthesize window;

-(void)initWithLoginService:(NSResponder <LoginServiceDelegate> *)delegate
{
  _delegate = delegate;
  [self initWithNibName: @"LoginScreen" bundle: nil];
  [_delegate setController: self];
}

-(void) awakeFromNib
{
  [super awakeFromNib];
  [[self email] setFocusRingType: NSFocusRingTypeNone];
  [[self password] setFocusRingType: NSFocusRingTypeNone];
}

-(IBAction) signInClicked: (id) sender
{
  [_delegate signIn: sender];
}

-(IBAction) forgotPasswordClicked: (id) sender
{
  [_delegate forgotPassword: sender];
}

@end
