#
#  UserTable.rb
#  port
#
#  Created by Kelly Martin on 4/23/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class UserTable

  # for user list
  def tableView(tableView, objectValueForTableColumn:column, row:rowIndex)
    if column.identifier == 'password'
      if rowIndex == tableView.editedRow
        auth_users[rowIndex]['password']
      else
        '*' * auth_users[rowIndex]['password'].length
      end
    else
      auth_users[rowIndex]['username']
    end
  end

  def numberOfRowsInTableView tableView
    auth_users.size
  end

  def tableView(tableView, setObjectValue:value, forTableColumn:column, row: rowIndex)
    if column.identifier == 'password'
      auth_users[rowIndex]['password'] = value
    else
      auth_users[rowIndex]['username'] = value
    end
  end

  def connector
    ConnectorsViewController.sharedController.selectedConnector
  end

  def auth_users
    Logger.debug 'calling auth'
    Logger.debug ConnectorsViewController.sharedController.auth_users.inspect
    ConnectorsViewController.sharedController.auth_users
  end

  def addUser(sender)
    auth_users << {'username' => '', 'password' => ''}
    ConnectorsViewController.sharedController.manage_users_table.reloadData
    ConnectorsViewController.sharedController.manage_users_table.selectRowIndexes NSIndexSet.alloc.initWithIndex(auth_users.size-1), byExtendingSelection:false
    ConnectorsViewController.sharedController.manage_users_table.editColumn 0, row: auth_users.size-1, withEvent:nil, select: true
  end

  def removeUser(sender)
    auth_users.delete_at ConnectorsViewController.sharedController.manage_users_table.selectedRow
    ConnectorsViewController.sharedController.manage_users_table.reloadData
  end
end
