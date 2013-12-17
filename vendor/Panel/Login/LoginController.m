//
//  LoginController.rb
//  port
//
//  Created by Kelly Martin on 4/2/13.
//  Copyright 2013 Kelly Martin. All rights reserved.
//

#import "LoginController.h"

@implementation LoginController

static LoginController * loginControllerSingleton;

+ (LoginController *) sharedController {
  @synchronized(self)
  {
    if (loginControllerSingleton == NULL)
      loginControllerSingleton = [[self alloc] init];
  }
  return(loginControllerSingleton);
}

+ (void) close {
  if (loginControllerSingleton) {
    [loginControllerSingleton close];
    [loginControllerSingleton release];
  }
}

- (id)init
{
  self = [super init];
  if (self) {
    loginWindow = [[[LoginWindow alloc] initWithContentRect:
                                                         NSMakeRect(0, 0, 240, 359)
                                                         styleMask: NSClosableWindowMask | NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                         defer:true] retain];
    [loginWindow setOpaque: false];
    [loginWindow setBackgroundColor: [NSColor colorWithPatternImage: [NSImage imageNamed: @"portly-login"]]];
    [self setWindow: loginWindow];
    [[LoginViewController sharedController] setWindow: self];
    [[self window] center];
    [[[self window] contentView] addSubView: [[LoginViewController sharedController] view]];
    [[self window] setInitialFirstResponder: [[LoginViewController sharedController] view]];
    [[self window] makeKeyAndOrderFront: nil];
    [[self window] setLevel: NSFloatingWindowLevel];
  }
  return self;
}

- (IBAction)showWindow:(id)sender {
  [[self window] center];
  [self super];
}

@end

