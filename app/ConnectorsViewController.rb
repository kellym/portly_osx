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
  attr_accessor :subdomain
  attr_accessor :cname
  attr_accessor :start_on_boot
  attr_accessor :authentication
  attr_accessor :connector_panel
  attr_accessor :remove_connector_panel
  attr_accessor :connector_box

  attr_accessor :new_connection_string
  attr_accessor :new_cname
  attr_accessor :new_subdomain

  attr_accessor :manage_users_button
  attr_accessor :manage_users_panel
  attr_accessor :manage_users_table

  attr_accessor :auth_users
  attr_accessor :initialized

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
    @initialized = true
  end

  def setup
    @connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(0), byExtendingSelection:true
    @suffix.stringValue = ".#{App.global.token_model.suffix}"
    @new_suffix.stringValue = ".#{App.global.token_model.suffix}"
  end

  def title
    "Tunnels"
  end

  def image
    NSImage.imageNamed('link')
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
    # populate the data on the right
    connector = App.global.connectors[self.connectors_list.selectedRow]
    if connector
      self.connector_box.setHidden false
      if self.connection_string != @currently_selected_field
        self.connection_string.stringValue = connector.connection_string || ''
      end
      self.cname.stringValue = connector.cname || ''
      self.subdomain.stringValue = connector.subdomain || ''
      self.start_on_boot.state = connector.start_on_boot || false
      if App.free?
        self.authentication.setHidden( true )
      else
        self.authentication.selectItemAtIndex connector.auth_type == 'basic' ? 1 : 0
      end
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
      data[:connection_string] = self.new_connection_string.stringValue
      data[:cname] = self.new_cname.stringValue
      data[:subdomain] = self.new_subdomain.stringValue
      data[:start_on_boot] = true
      ConnectorMonitor.create(data)

      self.connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(self.connectors_list.numberOfRows-1), byExtendingSelection:true
      hideNewConnectorPane(sender)
    else
      NSRunAlertPanel('Required fields are missing.', "All fields are required." , "OK", nil, nil)
    end
  end

  def setStartOnBoot(sender)
    connector = App.global.connectors[self.connectors_list.selectedRow]
    connector.start_on_boot = self.start_on_boot.state
    connector.save
  end

  def showNewConnectorPane(sender)
    self.new_connection_string.stringValue = ''
    self.new_cname.stringValue = ''
    self.new_subdomain.stringValue = ''
    self.new_connection_string.becomeFirstResponder
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
    App.global.connectors[self.connectors_list.selectedRow].destroy
    self.connectors_list.removeRowsAtIndexes NSIndexSet.indexSetWithIndex(selectedRow), withAnimation: NSTableViewAnimationSlideUp
    if selectedRow < self.connectors_list.numberOfRows
      selectedRow -= 1
    end

    selectedRow = 0 if selectedRow < 0
    self.connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(selectedRow), byExtendingSelection:true
  end

  def hideRemoveConnectorPane(sender)
    NSApp.endSheet self.remove_connector_panel
    self.remove_connector_panel.orderOut sender
  end

  def setHTTPAuthentication(sender)
    #self.authentication.indexOfSelectedItem
    self.manage_users_button.setHidden( App.free? || (self.authentication.indexOfSelectedItem == 0 ) )
    self.saveConnector(sender)
  end

  def saveConnector(sender)
    connector = App.global.connectors[self.connectors_list.selectedRow]
    Logger.debug self.authentication.indexOfSelectedItem
    Logger.debug "SAVING CONNECTOR"
    connector.auth_type = App.free? ? nil : (self.authentication.indexOfSelectedItem == 1 ? 'basic' : nil)
    connector.connection_string = self.connection_string.stringValue || ''
    connector.cname = self.cname.stringValue || ''
    connector.subdomain = self.subdomain.stringValue || ''
    connector.start_on_boot = self.start_on_boot.state || false
    connector.save
    ApplicationController.singleton.save
  end

  def controlTextDidChange(notification)
    connector = App.global.connectors[self.connectors_list.selectedRow]
    case notification.object
    when self.cname
      connector.cname = self.cname.stringValue
    when self.subdomain
      connector.subdomain = self.subdomain.stringValue
    when self.connection_string
      connector.connection_string = self.connection_string.stringValue
    end

    selectedRow = self.connectors_list.selectedRow
    connector.save
    #self.connectors_list.reloadData()
    self.connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(selectedRow), byExtendingSelection:true
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
    selectedConnector.auth_users = @auth_users
    selectedConnector.setAuthUsers
    hideManageUsersWindow(sender)
  end

  def hideManageUsersWindow(sender)
    NSApp.endSheet self.manage_users_panel
    self.manage_users_panel.orderOut sender
  end

  def selectedConnector
    App.global.connectors[self.connectors_list.selectedRow]
  end

  def triggerTempUsersTable
    Logger.debug selectedConnector.auth_users.inspect
    @auth_users = selectedConnector.auth_users.map { |v| v.dup }
  end

end
