#import "LoginViewController.h"

@interface LoginViewController

static LoginViewController * loginViewControllerSingleton;

+ (LoginViewController *) sharedController {
  @synchronized(self)
  {
    if (loginViewControllerSingleton == NULL)
      loginViewControllerSingleton = [[self alloc] init];
  }
  return(loginViewControllerSingleton);
}

-(void) awakeFromNib
{
  if(super) {
    [[self email] setFocusRingType: NSFocusRingTypeNone];
    [[self password] setFocusRingType: NSFocusRingTypeNone];
  }
}

-(IBAction) signInClicked: (id) sender
{
  [[[[LoginService alloc] init] signIn: sender] release];
}

-(IBAction) forgotPasswordClicked: (id) sender
{
  [[[[LoginService alloc] init] forgotPassword: sender] release];
}

@end
