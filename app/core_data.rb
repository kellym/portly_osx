# core_data.rb
# Suru
#
# Created by Patrick Thomson on 5/25/10.
# Released under the Ruby License.


module CoreDataSupport
  # Returns the support folder for the application, used to store the Core Data
  # store file.  This code uses a folder named "Suru" for
  # the content, either in the NSApplicationSupportDirectory location or (if the
  # former cannot be found), the system's temporary directory.
  def applicationSupportFolder
      return @application_support_folder if @application_support_folder

      paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
      path = (paths.count > 0) ? paths[0] : NSTemporaryDirectory
      @application_support_folder = File.join(path, App.title.downcase)
      Logger.debug "writing path"
      Logger.debug @application_support_folder
      unless NSFileManager.defaultManager.fileExistsAtPath @application_support_folder
        e = Pointer.new('@')
        NSFileManager.defaultManager.createDirectoryAtPath @application_support_folder, withIntermediateDirectories: true, attributes: nil, error: e
        Logger.debug "path written"
      end
      @application_support_folder

      #paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true)
      #basePath = (paths.count > 0) ? paths[0] : NSTemporaryDirectory()
      #return basePath.stringByAppendingPathComponent("App")
  end

  # Creates and returns the managed object model for the application
  # by merging all of the models found in the application bundle.
  def managedObjectModel
    Logger.debug "getting managedObjectModel"
    @managedObjectModel ||= NSManagedObjectModel.mergedModelFromBundles(nil)
  end


  # Returns the persistent store coordinator for the application.  This
  # implementation will create and return a coordinator, having added the
  # store for the application to it.  (The folder for the store is created,
  # if necessary.)
  def persistentStoreCoordinator
    unless @persistentStoreCoordinator
      error = Pointer.new_with_type('@')

      fileManager = NSFileManager.defaultManager
      applicationSupportFolder = self.applicationSupportFolder

      if !fileManager.fileExistsAtPath(applicationSupportFolder, isDirectory:nil)
        fileManager.createDirectoryAtPath(applicationSupportFolder, attributes:nil)
      end

      url = NSURL.fileURLWithPath(applicationSupportFolder.stringByAppendingPathComponent(App.data_file))
      @persistentStoreCoordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(self.managedObjectModel)
      if !@persistentStoreCoordinator.addPersistentStoreWithType(NSBinaryStoreType, configuration:nil, URL:url, options:nil, error:error)
        NSApplication.sharedApplication.presentError(error[0])
      end
    end

    @persistentStoreCoordinator
  end


  # Returns the NSUndoManager for the application.  In this case, the manager
  # returned is that of the managed object context for the application.
  def windowWillReturnUndoManager(window)
    managedObjectContext.undoManager
  end

  # Returns the managed object context for the application (which is already
  # bound to the persistent store coordinator for the application.)
  def managedObjectContext

    unless @managedObjectContext
      coordinator = self.persistentStoreCoordinator
      if coordinator
        @managedObjectContext = NSManagedObjectContext.alloc.init
        @managedObjectContext.setPersistentStoreCoordinator(coordinator)
      end
    end

    @managedObjectContext
  end


  # Implementation of the applicationShouldTerminate: method, used here to
  # handle the saving of changes in the application managed object context
  # before the application terminates.
  def applicationShouldTerminate(sender)
    error = Pointer.new_with_type('@')
    reply = NSTerminateNow

    if self.managedObjectContext
      if self.managedObjectContext.commitEditing
        if self.managedObjectContext.hasChanges and !self.managedObjectContext.save(error)
          # This error handling simply presents error information in a panel with an
          # "Ok" button, which does not include any attempt at error recovery (meaning,
          # attempting to fix the error.)  As a result, this implementation will
          # present the information to the user and then follow up with a panel asking
          # if the user wishes to "Quit Anyway", without saving the changes.

          # Typically, this process should be altered to include application-specific
          # recovery steps.

          errorResult = NSApplication.sharedApplication.presentError(error[0])

          if errorResult
            reply = NSTerminateCancel
          else
            alertReturn = NSRunAlertPanel(nil, "Could not save changes while quitting. Quit anyway?" , "Quit anyway", "Cancel", nil)
            if alertReturn == NSAlertAlternateReturn
              reply = NSTerminateCancel
            end
          end
        end
      else
        reply = NSTerminateCancel
      end
    end

    return reply
  end
end
