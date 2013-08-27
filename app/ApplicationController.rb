#
#  AppDelegate.rb
#  port forward
#
#  Created by Kelly Martin on 3/3/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#

class ApplicationController

    include CoreDataSupport

    attr_accessor :window
    attr_accessor :status_menu
    attr_accessor :connectors_menu

    attr_accessor :textField
    attr_accessor :preferences_window

    attr_accessor :online_state
    attr_accessor :change_state
    attr_accessor :preferences_menu

    attr_accessor :mco
    attr_accessor :socket

    def initialize
        @@singleton = self
    end

    def self.singleton
        @@singleton
    end

    def self.offline_orb
        @offline_orb ||= NSImage.imageNamed('away')
    end

    def self.online_orb
        @online_orb ||= NSImage.imageNamed('available')
    end

    def addConnector(record)
        ConnectorMonitor.new(record)
    end

    def save
      App.save!
    end

    def drawLoginScreen
        NSApplication.sharedApplication.activateIgnoringOtherApps(true)
        LoginController.sharedController.showWindow nil
    end

    def createPortlyFolder

        # Create App directory if not exists:

        fileManager = NSFileManager.new
        bundleID = NSBundle.mainBundle.bundleIdentifier
        urlPaths = fileManager.URLsForDirectory NSApplicationSupportDirectory, inDomains: NSUserDomainMask

        appDirectory = urlPaths.objectAtIndex 0, URLByAppendingPathComponent: bundleID, isDirectory:true

        # TODO: handle the error
        if !fileManager.fileExistsAtPath(appDirectory.path)
            fileManager.createDirectoryAtURL appDirectory, withIntermediateDirectories:false, attributes:nil, error:nil
        end

        App.global.path = appDirectory.path
    end

    def startApp
      self.performSelectorInBackground('startAppInBackground:', withObject: nil)
    end

    def startAppInBackground(obj)
      # let's do the tcp socket thing here
      if @socket
        @socket.startSocket
      else
        @socket = Stream.new
      end

      Logger.debug "Socket opened."
      Logger.debug "Connectors loaded."
      # verify that our token is still valid.
      data = {
          'computer_model' => Computer.machineModel,
          'computer_name' => NSHost.currentHost.localizedName,
          'access_token' => App.global.token,
          'uuid' => App.global.uuid
      }
      res = App.api_put("/tokens/#{App.global.token}", data)
      Logger.debug 'started'
      if res
        App.global.token_model.suffix = res['suffix']
        App.global.plan_type = res['plan_type']
        App.save!
        loadConnectors
        ConnectorsViewController.setup
        @preferences_menu.setEnabled(true)
        @add_tunnel_menu.setEnabled(true)
      else
        # we need to close out this joint, yo!
        Logger.debug "Putting token failed. Signing out."
        signOut
      end
    end

    def getUUID
      if NSUserDefaults.standardUserDefaults['uuid']
        App.global.uuid = NSUserDefaults.standardUserDefaults['uuid']
      else
        App.global.uuid = UUID.uuidString
        NSUserDefaults.standardUserDefaults.setObject App.global.uuid, forKey:"uuid"
        NSUserDefaults.standardUserDefaults.synchronize
      end
    end

    def initWithNibName(name, bundle: bundle)
      super
      self
    end

    def addTunnel(sender)
      showPreferences(sender)
      PreferencesController.sharedController.showWindow(sender)
      PreferencesController.sharedController.switchToModule(PreferencesController.sharedController.modules.first)
      ConnectorsViewController.sharedController.showNewConnectorPane(sender)
    end

    def awakeFromNib

      Logger.debug "awake app"
      getUUID
      createPortlyFolder

      Logger.debug "Setting up menu"
      @updater = SUUpdater.new
      @status_menu = NSMenu.new

      Logger.debug '- online state'
      @online_state = NSMenuItem.new
      @online_state.title = 'State: Disconnected'
      @online_state.setEnabled(false)

      @status_menu.addItem @online_state
      @status_menu.addItem(NSMenuItem.separatorItem)

      @add_tunnel_menu =  NSMenuItem.alloc.initWithTitle("Add a tunnel...", action: 'addTunnel:', keyEquivalent: '')
      @add_tunnel_menu.setTarget self
      @add_tunnel_menu.setEnabled(false)
      @status_menu.addItem @add_tunnel_menu

      Logger.debug '- prefs menu'
      @preferences_menu =  NSMenuItem.alloc.initWithTitle("Preferences", action: 'showPreferences:', keyEquivalent: ',')
      @preferences_menu.setTarget self
      @preferences_menu.setEnabled(false)
      @status_menu.addItem @preferences_menu

      @status_menu.addItem(NSMenuItem.separatorItem)
      Logger.debug '- updater'
      updater = NSMenuItem.alloc.initWithTitle("Check for update...", action: 'checkForUpdates:', keyEquivalent: 'u')
      updater.setTarget @updater
      @status_menu.addItem updater
      @status_menu.addItem(NSMenuItem.separatorItem)
      @status_menu.addItemWithTitle("Quit Portly", action: 'terminate:', keyEquivalent: 'q')

      #Logger.debug 'Creating notification.'
      #@notification ||= Notification.new(App.title)

      Logger.debug "Putting it on the menu"
      @statusItem = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
      @statusItem.setMenu @status_menu
      @statusItem.setToolTip App.title
      @statusItem.setHighlightMode true

      @status_menu.setAutoenablesItems false
      setMenuItemState :disconnected

      Logger.debug ("Loading tokens.")
      @tokens = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Token', andPredicate:nil, options:{}).keep_if { |t| t.active == 1 }
      Logger.debug "Tokens loaded."
      if @tokens.size > 0
          App.global.token = @tokens.first
          startApp
      else
          drawLoginScreen
      end

      NSNotificationCenter.defaultCenter.addObserver self, selector:'applicationWillTerminate:', name:NSApplicationWillTerminateNotification, object:NSApplication.sharedApplication
    end

    def setMenuItemState(state=:connected)
      @statusItem.setImage NSImage.imageNamed("icon-#{state.to_s}")
      @statusItem.setAlternateImage NSImage.imageNamed("icon-#{state.to_s}-on")
    end

    def validateMenuItem(menuItem)
      false
    end

    def loadConnectors
      ConnectorMonitor.load_all
      self.handleMenuDivider
    end

    def handleMenuDivider
      if !@divider && (App.global.connectors.size > 0)
        @divider = NSMenuItem.separatorItem
        self.status_menu.insertItem @divider, atIndex: App.global.index + App.global.connectors.size
      elsif @divider && App.global.connectors.size == 0
        self.status_menu.removeItem @divider if @divider && @divider.menu
        @divider = nil
      end
    end

    def showPreferences(sender)
      NSApplication.sharedApplication.activateIgnoringOtherApps(true)
      Logger.debug 'show pref window'
      PreferencesController.sharedController.showWindow(sender)
    end

    def applicationWillTerminate(a_notification)
      Logger.debug 'Terminating.'
      self.dealloc
    end

    def saveSettings
        NSUserDefaults.standardUserDefaults.synchronize
    end

    def toggleState(sender)
      if  sender.title == "Connect All"
        connectAll
      else
        disconnectAll
      end
    end

    def connectAll
      #@notification.send("Connecting ports to the outside world.")
      App.global.connectors.each do |connector|
        connector.connect unless connector.running?
      end
      @online_state.title = "State: Online"
      @change_state.title = "Disconnect All"
    end

    def disconnectAll
      #@notification.send("Disconnecting ports from the outside world.")
      App.global.connectors.each do |connector|
        connector.disconnect if connector.running?
      end

      @online_state.title = "State: Offline"
      @change_state.title = "Connect All"
    end

    def dealloc
      Logger.debug "Disconnecting all ports."
      @socket.closeSocket if @socket
      App.global.connectors.each do |connector|
        connector.disconnect
        connector.thread.exit if connector.thread
      end
    end

    def setConnectorState
      statuses = App.global.connectors.map(&:online?)

      if statuses.empty? || !statuses.include?(true)
        setMenuItemState :disconnected
        status = 'Disconnected'
      else
        setMenuItemState :connected
        count = 0
        statuses.each do |c|
          count += 1 if c
        end
        status = "#{count} Open Connection#{count == 1 ? '' : 's'}"
      end

      @online_state.title = "State: #{status}"
    end

    def signOut
      @preferences_menu.setEnabled(false)
      @add_tunnel_menu.setEnabled(false)
      File.delete(App.private_key_path) if File.exists?(App.private_key_path)
      File.delete(App.public_key_path) if File.exists?(App.public_key_path)
      ApplicationController.singleton.drawLoginScreen

      self.performSelectorInBackground('destroy_data:', withObject: nil)
      App.global.token = nil
      ApplicationController.singleton.socket.closeSocket
      ApplicationController.singleton.dealloc
      PreferencesController.sharedController.close rescue nil
    end

    def destroy_data(obj)
      tokens = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Token', andPredicate:nil, options:{})
      tokens.each do |t|
        t.active = 0
      end
      App.save!
      dups = []
      App.global.connectors.each { |c| dups << c }
      dups.each do |connector|
        Logger.debug connector.subdomain
        connector.disconnect
        connector.destroy_model
      end
    end
end

