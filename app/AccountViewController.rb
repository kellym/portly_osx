#
#  AccountViewController.rb
#  port
#
#  Created by Kelly Martin on 4/3/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class AccountViewController < NSViewController

    attr_accessor :allow_remote
    attr_accessor :connected_as
    attr_accessor :start_on_login

    def self.sharedController
        unless @sharedInstance
            @sharedInstance = self.alloc.initWithNibName("PreferencesAccount", bundle:nil)
        end
        @sharedInstance
    end

    def awakeFromNib
        @allow_remote.state = App.global.token_model.allow_remote || false
        @launchController ||= LaunchAtLoginController.alloc.init
        @start_on_login.state = @launchController.launchAtLogin
        @connected_as.stringValue = "You are connected as #{NSHost.currentHost.localizedName}."
    end

    def identifier
        PrefsToolbarItemAccount
    end

    def title
        "Account"
    end

    def image
        NSImage.imageNamed('account')
    end

    def disconnectAccounts(sender)
        ApplicationController.singleton.signOut
    end

    def setAllowRemote(sender)
        App.global.token_model.allow_remote = self.allow_remote.state #App.global.token_model.allow_remote == 0 ? 1 : 0
        ApplicationController.singleton.save
        @set_remote ||= Dispatch::Queue.new('set_remote')
        @set_remote.async do
            'Logger.debug setting auth'
            data = {
                'allow_remote' => App.global.token_model.allow_remote == 1 ? 'true' : 'false'
            }
            Logger.debug data['allow_remote']
            res = App.api_put("/api/authorizations", data)
            Logger.debug res.inspect
        end
    end

    def setStartOnLogin(sender)
        @launchController.setLaunchAtLogin self.start_on_login.state
    end
end
