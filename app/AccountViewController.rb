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


end
