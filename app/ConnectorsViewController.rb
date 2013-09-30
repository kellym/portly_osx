#
#  ConnectorsViewController.rb
#  port
#
#  Created by Kelly Martin on 3/5/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class ConnectorsViewController < NSViewController

  attr_accessor :menu
  attr_accessor :connectors
  attr_accessor :connectors_list
  attr_accessor :basic_view
  attr_accessor :suffix
  attr_accessor :new_suffix

  attr_accessor :connection_string
  attr_accessor :connection_type_view
  attr_accessor :connection_type
  attr_accessor :connection_type_raw_tcp_socket
  attr_accessor :subdomain
  attr_accessor :cname
  attr_accessor :authentication
  attr_accessor :use_http_authentication
  attr_accessor :connector_panel
  attr_accessor :remove_connector_panel
  attr_accessor :connector_box

  attr_accessor :new_connection_type_view
  attr_accessor :new_connection_string
  attr_accessor :new_connection_type
  attr_accessor :new_cname
  attr_accessor :new_subdomain
  attr_accessor :new_connection_type_raw_tcp_socket

  attr_accessor :manage_users_button
  attr_accessor :manage_users_panel
  attr_accessor :manage_users_table

  attr_accessor :auth_users
  attr_accessor :initialized

  attr_accessor :char_formatter
  attr_accessor :start_on_boot

  def initialize
    @previously_selected_row = nil
  end

  def self.setup
    if initialized?
      @sharedInstance.setup
    end
  end

  def self.initialized?
    @sharedInstance && @sharedInstance.initialized
  end

  def self.sharedController
    unless @sharedInstance
      @sharedInstance = self.alloc.initWithNibName("PreferencesConnectors", bundle:nil)
      @sharedInstance.auth_users = []
    end
    @sharedInstance
  end

  def awakeFromNib
    setup
    NSNotificationCenter.defaultCenter.addObserver( self,
                                         selector: "newPopupSelectionChanged:",
                                             name: NSMenuDidSendActionNotification,
                                           object: self.new_connection_type.menu)
    NSNotificationCenter.defaultCenter.addObserver( self,
                                         selector: "popupSelectionChanged:",
                                             name: NSMenuDidSendActionNotification,
                                           object: self.connection_type.menu)
    @initialized = true
  end

  def popupSelectionChanged(sender)
    #if sender == self.new_connection_type.menu
    title = self.connection_type.titleOfSelectedItem
    self.connection_type.setTitle title

    hide = title != 'Web Server'
    self.connection_type_view.setHidden hide
    connector = App.global.connectors[@selectedRow]
    connector.socket_type = ConnectorMonitor.parse_socket_type(self.connection_type.title)
    connector.save
  end


  def newPopupSelectionChanged(sender)
    #if sender == self.new_connection_type.menu
    title = self.new_connection_type.titleOfSelectedItem
    self.new_connection_type.setTitle title

    hide = title != 'Web Server'
    self.new_connection_type_view.setHidden hide
  end

  def setup
    @connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(0), byExtendingSelection:true
    if App.global.token_model
      @suffix.stringValue = "-#{App.global.token_model.suffix}"
      @new_suffix.stringValue = "-#{App.global.token_model.suffix}"
    end
    @formatter = AlphaNumericFormatter.new
    @subdomain.formatter = @formatter
    @new_subdomain.formatter = @formatter
    if App.free?
      @new_connection_type.setEnabled false
      @start_on_boot.setEnabled false
      @connection_type.setEnabled false
      @new_connection_type.setTitle "Web Server"
      @connection_type.setTitle "Web Server"
      @authentication.setEnabled false
      @authentication.selectItemAtIndex 0
      self.new_connection_type_view.setHidden false
    else
      @start_on_boot.setEnabled true
      @new_connection_type.setEnabled true
      @connection_type.setEnabled true
      @authentication.setEnabled true
    end
  end

  def title
    "Ports"
  end

  def image
    NSImage.imageNamed('tunnels')
  end

  def identifier
    PrefsToolbarItemConnectors
  end

  def numberOfRowsInTableView tableView
    if tableView == self.connectors_list
      App.global.connectors.size
    elsif tableView == self.manage_users_table
      2
    end
  end

  # for connector list
  def tableView(tableView, viewForTableColumn:column, row:rowIndex)
    if tableView == self.connectors_list
      connector = App.global.connectors[rowIndex]
      return connector.pref tableView
    elsif tableView == self.manage_users_table
      Logger.debug 'setting manage users table'
      cell = NSTableCellView.new
      text =  NSTextField.new
      text.stringValue = "data"
      cell.textField = text
      cell.objectValue = "data"
      cell
    end
  end

  def tableViewSelectionDidChange(notification)
    if self.connectors_list.selectedRow > -1
      @selectedRow = self.connectors_list.selectedRow
    end
    # populate the data on the right
    connector = App.global.connectors[@selectedRow]
    if connector
      self.connector_box.setHidden false
      if self.connection_string != @currently_selected_field
        self.connection_string.stringValue = connector.connection_string_with_nickname || ''
      end
      title = case connector.socket_type
              when 'http'
                'Web Server'
              when 'tcp'
                'Raw TCP Socket'
              else
                'Web Server'
              end
      @connection_type.setTitle title
      @connection_type_view.setHidden(connector.socket_type == 'tcp')
      self.cname.stringValue = connector.cname || ''
      self.subdomain.stringValue = connector.subdomain || ''
      if App.free?
        self.authentication.selectItemAtIndex 0
        @start_on_boot.setEnabled false
        @connection_type.setEnabled false
        @connection_type.setTitle "Web Server"
        self.start_on_boot.state = false
      else
        self.start_on_boot.state = connector.start_on_boot || false
        @connection_type.setEnabled true
        self.authentication.selectItemAtIndex connector.auth_type == 'basic' ? 1 : 0
      end
      @authentication.setEnabled !App.free?
      self.manage_users_button.setHidden( App.free? || (connector.auth_type != 'basic') )
    else
      # hide all that stuff
      self.connector_box.setHidden true
    end
  end

  def controlTextDidBeginEditing(notification)
    @currently_selected_field = notification.object
  end

  def controlTextDidEndEditing(notification)
    @currently_selected_field = nil
  end

  def addConnector(sender)
    if self.new_connection_string && self.new_cname && self.new_subdomain
      data = {}
      # continue with creation
      data[:socket_type] = self.new_connection_type.title
      data[:connection_string] = self.new_connection_string.stringValue
      data[:cname] = self.new_cname.stringValue
      data[:subdomain] = self.new_subdomain.stringValue
      data[:start_on_boot] = false
      ConnectorMonitor.create(data)

      self.connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(self.connectors_list.numberOfRows-1), byExtendingSelection:true
      hideNewConnectorPane(sender)
    else
      NSRunAlertPanel('Required fields are missing.', "All fields are required." , "OK", nil, nil)
    end
  end

  def setStartOnBoot(sender)
    connector = App.global.connectors[@selectedRow]
    if App.free?
      connector.start_on_boot = false
    else
      connector.start_on_boot = self.start_on_boot.state
    end
    connector.save
  end

  def showNewConnectorPane(sender)
    @new_connection_type_raw_tcp_socket.setEnabled !App.free?
    @new_connection_string.removeAllItems
    ports = []
    ApplicationController.singleton.listOnlinePorts
    ApplicationController.singleton.ports.sort_by {|k,v| v}.each do |k,v|
      ports << "#{k} (#{v})"
    end
    @new_connection_string.stringValue = ''
    @new_connection_string.addItemsWithObjectValues ports
    #self.new_connection_string.stringValue = ''
    self.new_cname.stringValue = ''
    self.new_subdomain.stringValue = ''
    #self.new_connection_string.becomeFirstResponder
    NSApp.beginSheet self.connector_panel,
        modalForWindow: PreferencesController.sharedController.window,
        modalDelegate:self,
        didEndSelector:nil,
        contextInfo:nil
  end

  def hideNewConnectorPane(sender)
    NSApp.endSheet self.connector_panel
    self.connector_panel.orderOut sender
  end

  def showRemoveConnectorPane(sender)
    NSApp.beginSheet self.remove_connector_panel,
      modalForWindow: PreferencesController.sharedController.window,
      modalDelegate:self,
      didEndSelector:nil,
      contextInfo:nil
  end

  def removeConnector(sender)
    self.hideRemoveConnectorPane(sender)
    selectedRow = self.connectors_list.selectedRow
    if selectedRow > -1
      @selectedRow = selectedRow - 1
      @selectedRow = 0 if @selectedRow < 0
      App.global.connectors[selectedRow].destroyRecordAndSelect @selectedRow, sender
      #self.connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(@selectedRow), byExtendingSelection:true
      @currently_selected_field = nil
    end
    #tableViewSelectionDidChange(sender)
  end

  def hideRemoveConnectorPane(sender)
    NSApp.endSheet self.remove_connector_panel
    self.remove_connector_panel.orderOut sender
  end

  def setHTTPAuthentication(sender)
    self.manage_users_button.setHidden( App.free? || (self.authentication.indexOfSelectedItem == 0 ) )
    self.saveConnector(sender)
  end

  def saveConnector(sender)
    if @selectedRow
      connector = App.global.connectors[@selectedRow]
      Logger.debug self.authentication.indexOfSelectedItem
      Logger.debug "SAVING CONNECTOR"
      connector.auth_type = App.free? ? nil : (self.authentication.indexOfSelectedItem == 1 ? 'basic' : nil)
      connector.connection_string = self.connection_string.stringValue || ''
      connector.cname = self.cname.stringValue || ''
      connector.subdomain = self.subdomain.stringValue || ''
      if App.free?
        connector.start_on_boot = false
      else
        connector.start_on_boot = self.start_on_boot.state || false
      end
      connector.save
      ApplicationController.singleton.save
    end
  end

  def controlTextDidChange(notification)
    connector = App.global.connectors[@selectedRow]
    case notification.object
    when self.cname
      connector.cname = self.cname.stringValue
    when self.subdomain
      connector.subdomain = self.subdomain.stringValue
    when self.connection_string
      connector.connection_string = self.connection_string.stringValue
    end

    #selectedRow = self.connectors_list.selectedRow
    connector.save
    #self.connectors_list.reloadData()
    self.connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(@selectedRow), byExtendingSelection:true
  end

  def showManageUsersWindow(sender)
    self.triggerTempUsersTable
    self.manage_users_table.reloadData
    NSApp.beginSheet self.manage_users_panel,
      modalForWindow: PreferencesController.sharedController.window,
      modalDelegate:self,
      didEndSelector:nil,
      contextInfo:nil
  end

  def saveManageUsersWindow(sender)
    hideManageUsersWindow(sender)
    self.manage_users_table.reloadData
    selectedConnector.auth_users = @auth_users
    selectedConnector.setAuthUsers
  end

  def hideManageUsersWindow(sender)
    NSApp.endSheet self.manage_users_panel
    self.manage_users_panel.orderOut sender
  end

  def selectedConnector
    App.global.connectors[@selectedRow]
  end

  def triggerTempUsersTable
    Logger.debug selectedConnector.auth_users.inspect
    @auth_users = selectedConnector.auth_users.map { |v| v.dup }
  end

end
