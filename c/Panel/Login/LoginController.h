//
//  LoginController.h
//  port
//
//  Created by Kelly Martin on 4/3/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LoginWindow.h"
#import "LoginViewController.h"

@interface LoginController : NSWindowController {
  LoginWindow * loginWindow;
  LoginViewController * _delegate;
}

- (id)initWithLoginViewController:(LoginViewController *)delegate;
- (IBAction)showWindow:(id)sender;

@end
