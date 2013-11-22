#
#  AppDelegate.rb
#  port forward
#
#  Created by Kelly Martin on 3/3/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#
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
    attr_accessor :statusItemView
    attr_accessor :panel
    attr_accessor :ports

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
       self.panel.hideAddButton
        NSApplication.sharedApplication.activateIgnoringOtherApps(true)
        LoginController.sharedController.showWindow nil
    end

    def closeLogin
      LoginController.close
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
      Dispatch::Queue.main.async do
        self.panel.showBlankSlate
        self.panel.showAddButton
      end
      startAppInBackground(nil)
      #self.performSelectorInBackground('startAppInBackground:', withObject: nil)
    end

    def startAppInBackground(obj)
      # let's do the tcp socket thing here
      if @socket
        @socket.startSocket
      else
        @socket = Stream.new
      end

      Logger.debug "Socket opened."
      Logger.debug "Connectors loading."
      # verify that our token is still valid.
      data = {
          'computer_model' => Computer.machineModel,
          'computer_name' => NSHost.currentHost.localizedName,
          'access_token' => App.global.token,
          'version' => App.version,
          'uuid' => App.global.uuid
      }
      res = App.api_put("/tokens/#{App.global.token}", data)
      Logger.debug 'PUT TOKENS COMPLETE'
      if res
        App.global.token_model.suffix = res['suffix']
        App.global.plan_type = res['plan_type']
        set_plan_title
        App.save!
        loadConnectors
        ConnectorsViewController.setup
        @preferences_menu.setEnabled(true)
        self.panel.showAddButton
      else
        # we need to close out this joint, yo!
        Logger.debug "Putting token failed. Signing out."
        signOut
      end
    end

    def set_plan_title
      if 'Free' == App.global.plan_type
        header = NSMutableAttributedString.alloc.init
        link_name = "Upgrade to Portly Pro"
        url = NSURL.URLWithString App.upgrade_url
        hyperlinkString = NSMutableAttributedString.alloc.initWithString link_name
        hyperlinkString.beginEditing
        hyperlinkString.addAttribute NSLinkAttributeName, value: url, range: NSMakeRange(0, hyperlinkString.length)
        hyperlinkString.addAttribute NSForegroundColorAttributeName, value:App.link_color, range:NSMakeRange(0, hyperlinkString.length)
        hyperlinkString.endEditing
        header.appendAttributedString hyperlinkString
      else
        header = NSMutableAttributedString.alloc.initWithString "Portly Pro"
      end
      self.panel.header = header
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

    def listOnlinePorts
      # task: `lsof -i -n -P +c 0 | grep LISTEN`
      @task = NSTask.new
      @task.setLaunchPath("/usr/sbin/lsof")
      arr = ["-i", "-n", "-P", "+c", "0"]
      @task.setArguments(arr)

      po = NSPipe.new
      p_error = NSPipe.new
      @task.standardOutput = po
      @task.standardError = p_error
        @error_handle = p_error.fileHandleForReading
        @fh = po.fileHandleForReading
      @task.launch
      data = @fh.readDataToEndOfFile
      data2 = @error_handle.readDataToEndOfFile
      @task.waitUntilExit

      data = NSString.alloc.initWithData data, encoding: NSUTF8StringEncoding
      data = data.split("\n")
      data.keep_if { |l| l.match(/LISTEN/) }
      ports = {}
      data.each do |line|
        line = line.split(/\s+/)
        ports[line[-2].gsub('*', 'localhost')] = line[0] unless line[-2].match(/^\[/)
      end
      @ports = ports
      #Logger.debug @ports.inspect
      #ConnectorsViewController.sharedController.new_connection_string.removeAllItems
      #ConnectorsViewController.sharedController.new_connection_string.addItemsWithObjectValues(ports.values)
      # Logger.debug ports.inspect
    end

    def showPopup(sender)
      if !@popover
        @popover = NSPopover.new
        @popover.contentViewController = NSViewController.alloc.initWithNibName("PreferencesAccount", bundle:nil)
        @popover.animates = false
      end
      if @popover.isShown
        @popover.close
      else
        @statusItem.drawStatusBarBackgroundInRect(NSZeroRect,
                                withHighlight: true)
        @popover.showRelativeToRect(
          NSZeroRect,
          ofView: sender,
          preferredEdge: 1
        )
      end
    end

    def awakeFromNib

      Logger.debug "awake app"
      getUUID
      createPortlyFolder
      listOnlinePorts

      Logger.debug "Setting up menu"
      @updater = SUUpdater.new
      @status_menu = self.panel.statusMenu

      #@add_tunnel_menu =  NSMenuItem.alloc.initWithTitle("Add a port...", action: 'addTunnel:', keyEquivalent: '')
      #@add_tunnel_menu.setTarget self
      #@add_tunnel_menu.setEnabled(false)
      #@status_menu.addItem @add_tunnel_menu

      Logger.debug '- prefs menu'
      @preferences_menu =  NSMenuItem.alloc.initWithTitle("Preferences", action: 'showPreferences:', keyEquivalent: ',')
      @preferences_menu.setTarget self
      @preferences_menu.setEnabled(false)
      @status_menu.addItem @preferences_menu

      #@status_menu.addItem(NSMenuItem.separatorItem)
      #Logger.debug '- updater'
      updater = NSMenuItem.alloc.initWithTitle("Check for update...", action: 'checkForUpdates:', keyEquivalent: 'u')
      updater.setTarget @updater
      @status_menu.addItem updater
      @status_menu.addItem(NSMenuItem.separatorItem)
      @status_menu.addItemWithTitle("Quit Portly", action: 'terminate:', keyEquivalent: 'q')
      @status_menu.setAutoenablesItems false

      #Logger.debug 'Creating notification.'
      #@notification ||= Notification.new(App.title)

      Logger.debug "Putting it on the menu"
      @statusItem = NSStatusBar.systemStatusBar.statusItemWithLength 24
      @statusItemView = StatusItemView.alloc.initWithStatusItem @statusItem
      @statusItemView.action = "togglePanel:"
      @statusItemView.image = NSImage.imageNamed "icon-connected"
      @statusItemView.alternateImage = NSImage.imageNamed "icon-connected"
      @statusItemView.setNeedsDisplay true
      @statusItem.toolTip = "Portly"
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

    def applicationDidResignActive(sender=nil)
      Logger.debug "LOST FOCUS"
    end
    def appLostFocus(object=nil)
      Logger.debug "LOST FOCUS"
    end

    def setMenuItemState(state=:connected)
      @statusItemView.setImage NSImage.imageNamed("icon-#{state.to_s}")
      @statusItemView.setAlternateImage NSImage.imageNamed("icon-#{state.to_s}-on")
      @statusItemView.setNeedsDisplay true
    end


    def hasActiveIcon
      @statusItemView.isHighlighted
    end

    def hasActiveIcon=(flag)
      @statusItemView.setHighlighted flag
    end

    def validateMenuItem(menuItem)
      false
    end

    def loadConnectors
      App.global.connectors = []
      ConnectorMonitor.load_all
      self.panel.showAddButton
      if App.global.connectors.size == 0
        self.panel.showBlankSlate
        self.panel.triggerActivePanel true
      end
    end

    def handleMenuDivider
     # if !@divider && (App.global.connectors.size > 0)
     #   @divider = NSMenuItem.separatorItem
     #   #self.status_menu.insertItem @divider, atIndex: App.global.index + App.global.connectors.size
     # elsif @divider && App.global.connectors.size == 0
     #   self.status_menu.removeItem @divider if @divider && @divider.menu
     #   @divider = nil
     # end
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

    def closeLogin
      controller.close
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

      @stay_awake ||= StayAwake.new
      @stay_awake.stop
      if statuses.empty? || !statuses.include?(true)
        setMenuItemState :disconnected
        status = 'Disconnected'
      else
        setMenuItemState :connected
        count = 0
        statuses.each do |c|
          count += 1 if c
        end
        status = "#{count} Open Port#{count == 1 ? '' : 's'}"
        @stay_awake.start if App.stay_awake?
      end

      self.panel.title = "State: #{status}"
    end

    def signOut
      self.panel.header = NSAttributedString.alloc.initWithString ""
      @preferences_menu.setEnabled(false)
      #@add_tunnel_menu.setEnabled(false)
      self.panel.hideAddButton
      File.delete(App.private_key_path) if File.exists?(App.private_key_path)
      File.delete(App.public_key_path) if File.exists?(App.public_key_path)
      ApplicationController.singleton.drawLoginScreen

      self.performSelectorInBackground('destroy_data:', withObject: nil)
      #destroy_data(nil)
      App.global.token = nil
      ApplicationController.singleton.socket.closeSocket
      #ApplicationController.singleton.dealloc
      PreferencesController.sharedController.close rescue nil
    end

    def destroy_data(obj)
      tokens = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Token', andPredicate:nil, options:{})
      tokens.each do |t|
        t.active = 0
      end
      App.save!
      count = App.global.connectors.size
      Logger.debug "REMOVING THIS MANY: #{count}"
      @async_destroy ||= Dispatch::Queue.new('async_destroy')
      App.global.connectors.each do |c|
        Logger.debug "About to kill: #{c.connection_string}"
      end

      App.global.connectors.each do |c|
        #if c
          Logger.debug "KILL: #{c.connection_string}"
          c.disconnect(false) #, false)
          #c.thread.exit if c.thread
          c.remove_row
          #c.destroy_model
        #end
      end
      Logger.debug "ROWS LEFT: #{self.panel.rows.count}"
      self.panel.rows.count.times do
        self.panel.rows.first.remove
      end
      #self.panel.rows.each do |r|
      #  r.remove
      #end
      Logger.debug "CONNECTORS LEFT: #{App.global.connectors.size}"
      # just to make sure we destroy them all
      ConnectorMonitor.all.each do |c|
        ApplicationController.singleton.managedObjectContext.deleteObject c
      end
      App.save!
      App.global.connectors = []

      ConnectorsViewController.sharedController.connectors_list.reloadData if ConnectorsViewController.sharedController.connectors_list
      ConnectorsViewController.sharedController.connector_box.setHidden(true) if ConnectorsViewController.sharedController.connector_box
      self.panel.hideBlankSlate
    end
end

