#
#  LoginController.rb
#  port
#
#  Created by Kelly Martin on 4/2/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#

class LoginController < NSWindowController

    def self.sharedController
        unless @sharedInstance
            @sharedInstance = self.alloc.init
        end
        @sharedInstance
    end

    def init
        if super
            loginWindow = LoginWindow.alloc.initWithContentRect(
                                                         NSMakeRect(0, 0, 240, 359),
                                                         styleMask: NSClosableWindowMask | NSBorderlessWindowMask,
                                                         backing:NSBackingStoreBuffered,                                                         defer:true
                                                         )
            loginWindow.setOpaque false
            loginWindow.setBackgroundColor NSColor.colorWithPatternImage(NSImage.imageNamed('portly-login'))
            self.window = loginWindow
            viewController = LoginViewController.sharedController
            viewController.window = self
            self.window.center
            self.window.contentView.addSubview(viewController.view)
            self.window.setInitialFirstResponder(viewController.view)
            self.window.makeKeyAndOrderFront nil
            self.window.setLevel NSFloatingWindowLevel
        end

        self
    end

    def showWindow(sender)
        self.window.center
        super
    end


end
