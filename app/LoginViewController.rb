#
#  LoginViewController.rb
#  port
#
#  Created by Kelly Martin on 4/3/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#



class LoginViewController < NSViewController

    attr_accessor :email
    attr_accessor :password
    attr_accessor :error
    attr_accessor :window

    def self.sharedController
      unless @sharedInstance
        @sharedInstance = self.alloc.initWithNibName("LoginScreen", bundle:nil)
      end
      @sharedInstance
    end

    def awakeFromNib
        if super
            self.email.setFocusRingType NSFocusRingTypeNone
            self.password.setFocusRingType NSFocusRingTypeNone
        end
    end

    def signInClicked(sender)
        Dispatch::Queue.main.async do

          Logger.debug 'clicked'
            # handle getting the API token from the site
            tokens = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Token', andPredicate:nil, options:{})
            data = {
                'client_id' => App.client_id,
                'client_secret' => App.client_secret,
                'computer_name' => NSHost.currentHost.localizedName,
                'computer_model' => Computer.machineModel,
                'mac_address' => App.global.mac_address,
                'user[email]' => self.email.stringValue,
                'user[password]' => self.password.stringValue
            }
          Logger.debug 'data set for login'
            data['token'] = tokens.first.key if tokens.first
          Logger.debug 'posting'
            res = App.api_post("/authorizations",data)
          Logger.debug 'posted'
            unless res
                self.error.stringValue = case self.error.stringValue
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
                if self.error.stringValue == 'All right, here you go.'
                    forgotPasswordClicked(sender)
                end
            else
                result = res
                #Logger.debug result.inspect
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
                App.global.token = token
                savePrivateKeyToFile(result['private_key'])
                ApplicationController.singleton.startApp
                # gotta do something with the code now!!!
                ApplicationController.singleton.loadConnectors
                self.window.close
            end
        end
    end

    def forgotPasswordClicked(sender)
        NSWorkspace.sharedWorkspace.openURL NSURL.URLWithString(App.forgot_password_url)
        NSApp.terminate(sender)
    end

    def savePrivateKeyToFile(private_key)
        File.open(App.private_key_path, 'w') do |f|
            f << private_key
            f.chmod(0600)
        end
    end
end
