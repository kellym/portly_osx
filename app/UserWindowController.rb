#
#  UserWindowController.rb
#  port
#
#  Created by Kelly Martin on 4/23/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class UserWindowController < NSWindowController
  attr_accessor :window
  attr_accessor :table

  def self.sharedController
    unless @sharedInstance
      @sharedInstance = self.alloc.init
    end

    @sharedInstance
  end

  def init
    if super
      userWindow = NSWindow.alloc.initWithContentRect(
                                                   NSMakeRect(0, 0, 250, 200),
                                                   styleMask:NSTitledWindowMask | NSClosableWindowMask,
                                                   backing:NSBackingStoreBuffered,
                                                   defer:true
                                                   )
      self.window = userWindow
    end

    self
  end

end
