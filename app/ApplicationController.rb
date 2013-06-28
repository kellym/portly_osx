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
        connector = ConnectorMonitor.new(record)
    end

    def save
        error = Pointer.new_with_type('@')
        unless ApplicationController.singleton.managedObjectContext.save(error)
            NSApplication.sharedApplication.presentError(error[0])
        end
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

    def createSSHConnection

    end

    def startApp
        # let's do the tcp socket thing here
        @socket = Stream.new
        # verify that our token is still valid.
        @token_verification = Dispatch::Queue.new('token.check')
        @token_verification.async do
            data = {
                'computer_model' => Computer.machineModel,
                'computer_name' => NSHost.currentHost.localizedName,
                'access_token' => App.global.token,
                'mac_address' => App.global.mac_address
            }
            res = App.api_put("/tokens/#{App.global.token}", data)
            Logger.debug 'started'
            unless res
                # we need to close out this joint, yo!
                Dispatch::Queue.main.async do
                    signOut
                end
            end
        end
        @preferences_menu.setEnabled(true) if App.global.token
        ConnectorsViewController.sharedController.setup if ConnectorsViewController.initialized?
        loadConnectors
    end

    def getMACAddress
      if NSUserDefaults.standardUserDefaults['uuid']
        App.global.mac_address = NSUserDefaults.standardUserDefaults['uuid']
      else
        App.global.mac_address = UUID.uuidString
        NSUserDefaults.standardUserDefaults.setObject App.global.mac_address, forKey:"uuid"
        NSUserDefaults.standardUserDefaults.synchronize
      end
    end

    def initWithNibName(name, bundle: bundle)
      super
      self
    end



    def awakeFromNib

        getMACAddress
        createPortlyFolder
        createSSHConnection

        @updater = SUUpdater.new
        @status_menu = NSMenu.new

        @online_state = NSMenuItem.new
        @online_state.title = 'State: Disconnected'
        @online_state.setEnabled(false)

        @status_menu.addItem @online_state
        @status_menu.addItem(NSMenuItem.separatorItem)
        @preferences_menu =  NSMenuItem.alloc.initWithTitle("Preferences", action: 'showPreferences:', keyEquivalent: 'p')
        @preferences_menu.setTarget self
        @preferences_menu.setEnabled(false)
        @status_menu.addItem @preferences_menu
        updater = NSMenuItem.alloc.initWithTitle("Check for update...", action: 'checkForUpdates:', keyEquivalent: 'u')
        updater.setTarget @updater
        @status_menu.addItem updater
        @status_menu.addItem(NSMenuItem.separatorItem)
        @status_menu.addItemWithTitle("Quit Portly", action: 'terminate:', keyEquivalent: 'q')
        @notification ||= Notification.new(App.title)

        @statusItem = NSStatusBar.systemStatusBar.statusItemWithLength NSVariableStatusItemLength
        @statusItem.setMenu @status_menu
        @statusItem.setToolTip App.title
        @statusItem.setHighlightMode true

        @status_menu.setAutoenablesItems false
        setMenuItemState :disconnected


        @tokens = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Token', andPredicate:nil, options:{}).keep_if { |t| t.active == 1 }
        if @tokens.size > 0
            App.global.token = @tokens.first
            startApp
        else
            drawLoginScreen
        end

        NSNotificationCenter.defaultCenter.addObserver self, selector:'applicationWillTerminate:', name:NSApplicationWillTerminateNotification, object:NSApplication.sharedApplication

        Logger.debug NSUserDefaults.standardUserDefaults['user']
    end

    def setMenuItemState(state=:connected)
        @statusItem.setImage NSImage.imageNamed("icon-#{state.to_s}")
        @statusItem.setAlternateImage NSImage.imageNamed("icon-#{state.to_s}-on")
    end

    def validateMenuItem(menuItem)
        Logger.debug "VALIDATION"
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
        @notification.send("Connecting ports to the outside world.")
        App.global.connectors.each do |connector|
            connector.connect unless connector.running?
        end
        @online_state.title = "State: Online"
        @change_state.title = "Disconnect All"
    end

    def disconnectAll
        @notification.send("Disconnecting ports from the outside world.")
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

        statuses = App.global.connectors.map(&:online?).uniq

        if statuses == [true]
            setMenuItemState :connected
            status = 'Connected'
        elsif statuses == [false] || statuses == []
            setMenuItemState :disconnected
            status = 'Disconnected'
        else
            setMenuItemState :connected
            status = 'Partially Connected'
        end

        @online_state.title = "State: #{status}"
    end

    def signOut
        @preferences_menu.setEnabled(false)
        File.delete(App.private_key_path) if File.exists?(App.private_key_path)
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

