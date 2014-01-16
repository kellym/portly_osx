class LoginService

  def initialize

  end

  def setController(controller)
    @controller = controller
  end

  def signIn(sender)
    # handle getting the API token from the site
    tokens = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Token', andPredicate:nil, options:{})
    data = {
        'client_id' => App.client_id,
        'client_secret' => App.client_secret,
        'computer_name' => NSHost.currentHost.localizedName,
        'computer_model' => Computer.machineModel,
        'version' => App.version,
        'uuid' => App.global.uuid,
        'user[email]' => @controller.email.stringValue,
        'user[password]' => @controller.password.stringValue
    }
    data['token'] = tokens.first.key if tokens.first
    result = App.api_post("/authorizations", data)
    if result
      tokens = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Token', andPredicate:nil, options:{})
      tokens.each do |t|
          ApplicationController.singleton.managedObjectContext.deleteObject t
      end
      token = NSEntityDescription.insertNewObjectForEntityForName "Token", inManagedObjectContext:ApplicationController.singleton.managedObjectContext
      token.key = result['code']
      token.active = true
      token.allow_remote = true
      token.suffix = result['suffix']
      App.save!
      App.global.plan_type = result['plan_type']
      App.global.token = token
      App.savePublicKeyToFile(result['public_key'])
      App.savePrivateKeyToFile(result['private_key'])
      ApplicationController.singleton.startApp
      # gotta do something with the code now!!!
      @controller.window.close
    else
      @controller.error.stringValue = case @controller.error.stringValue
          when 'No luck. Try something else.'
              'Still no luck. Forgot it?'
          when 'Still no luck. Forgot it?'
              'You might need some help.'
          when 'You might need some help.'
              'No "might" about it anymore.'
          when 'No "might" about it anymore.'
              'All right, here you go.'
          else
              'No luck. Try something else.'
      end
      if @controller.error.stringValue == 'All right, here you go.'
          forgotPassword(sender)
      end
    end
  end

  def forgotPassword(sender)
    NSWorkspace.sharedWorkspace.openURL NSURL.URLWithString(App.forgot_password_url)
    NSApp.terminate(sender)
  end

end

