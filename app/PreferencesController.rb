#
#  PreferencesController.rb
#  port
#
#  Created by Kelly Martin on 3/10/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#

class PreferencesController < NSWindowController

    attr_accessor :connectorsPane
    attr_accessor :settingsPane
    attr_accessor :generalPane
    attr_reader :modules

    def self.sharedController
        unless @sharedInstance
            @sharedInstance = self.alloc.init
            connectors = ConnectorsViewController.sharedController
            account = AccountViewController.sharedController
            general = GeneralViewController.sharedController
            @sharedInstance.modules = [connectors, general, account]
        end

        @sharedInstance
    end

    def init
        if super
            prefsWindow = NSWindow.alloc.initWithContentRect(
                                                         NSMakeRect(0, 0, 550, 260),
                                                         styleMask:NSTitledWindowMask | NSClosableWindowMask,
                                                         backing:NSBackingStoreBuffered,
                                                         defer:true
                                                         )
            prefsWindow.setReleasedWhenClosed true
            prefsWindow.setShowsToolbarButton(false)
            self.window = prefsWindow

            setupToolbar
        end

        self
    end

  def toolbar(toolbar, itemForItemIdentifier:itemIdentifier, willBeInsertedIntoToolbar:flag)
    mod = moduleForIdentifier(itemIdentifier)
    NSToolbarItem.alloc.initWithItemIdentifier(itemIdentifier).tap do |item|
      if mod
        view = ToolbarItem.new
        image = ToolbarImage.new
        image.sender = item
        image.image = mod.image
        image.setFrameSize NSMakeSize(55, 32)
        image.target = self
        image.action = "selectModule:"
        image.setFrameOrigin NSMakePoint(0,18)
        view.addSubview image
        view.title = mod.title
        view.setFrameSize NSMakeSize(55, 55)
        view.target = self
        view.action = "selectModule:"
        view.sender = item

        item.setView view
      end
    end
  end

  def selectMenu(menu)
    Logger.debug 'menu selected'
  end

  def toolbarAllowedItemIdentifiers(toolbar)
    @modules.map { |mod| mod.identifier }
  end

  def toolbarDefaultItemIdentifiers(toolbar)
    nil
  end

  def toolbarSelectableItemIdentifiers(toolbar)
    toolbarAllowedItemIdentifiers(toolbar)
  end

  def showWindow(sender)
    self.window.center
    super
  end

  def selectModule(sender)
    mod = moduleForIdentifier(sender.itemIdentifier)
    switchToModule(mod) if mod
  end

  def modules=(newModules)
    @modules = newModules
    toolbar = self.window.toolbar
    return unless toolbar && toolbar.items.count == 0

    @modules.each do |mod|
      toolbar.insertItemWithItemIdentifier(mod.identifier, atIndex:toolbar.items.count)
    end

    savedIdentifier = NSUserDefaults.standardUserDefaults.stringForKey(PreferencesSelection)
    defaultModule = moduleForIdentifier(savedIdentifier) || @modules.first
    switchToModule(defaultModule)
  end

  def setupToolbar
    toolbar = NSToolbar.alloc.initWithIdentifier("preferencesToolbar")
    toolbar.delegate = self
    toolbar.setDisplayMode NSToolbarDisplayModeIconOnly
    toolbar.setAllowsUserCustomization(false)
    self.window.setToolbar(toolbar)
  end

  def switchToModule(mod)
    @currentModule.view.removeFromSuperview if @currentModule

    newView = mod.view

    windowFrame = self.window.frameRectForContentRect(newView.frame)
    windowFrame.origin = self.window.frame.origin;
    windowFrame.origin.y -= windowFrame.size.height - self.window.frame.size.height
    self.window.setFrame(windowFrame, display:true, animate:true)

    self.window.toolbar.setSelectedItemIdentifier(mod.identifier)
    self.window.title = mod.title

    @currentModule = mod
    self.window.contentView.addSubview(@currentModule.view)
    self.window.setInitialFirstResponder(@currentModule.view)

    NSUserDefaults.standardUserDefaults.setObject(mod.identifier, forKey:PreferencesSelection)
  end

  def moduleForIdentifier(identifier)
    @modules.find { |mod| mod.identifier == identifier }
  end
end
