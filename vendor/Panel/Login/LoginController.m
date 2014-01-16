//
//  LoginController.rb
//  port
//
//  Created by Kelly Martin on 4/2/13.
//  Copyright 2013 Kelly Martin. All rights reserved.
//

#import "LoginController.h"

@implementation LoginController

- (id)initWithLoginViewController: (LoginViewController *) delegate
{
  self = [super init];
  if (self) {
    _delegate = delegate;
    loginWindow = [[[LoginWindow alloc] initWithContentRect:
                                                         NSMakeRect(0, 0, 240, 359)
                                                         styleMask: NSClosableWindowMask | NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                         defer:true] retain];
    [loginWindow setOpaque: false];
    [loginWindow setBackgroundColor: [NSColor colorWithPatternImage: [NSImage imageNamed: @"portly-login"]]];
    [self setWindow: loginWindow];
    [_delegate setWindow: self];
    [[self window] center];
    [[[self window] contentView] addSubview: [_delegate view]];
    [[self window] setInitialFirstResponder: [_delegate view]];
    [[self window] makeKeyAndOrderFront: nil];
    [[self window] setLevel: NSFloatingWindowLevel];
  }
  return self;
}

- (IBAction)showWindow:(id)sender {
  [[self window] center];
}

@end

