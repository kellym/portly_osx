class GeneralViewController < NSViewController

  attr_accessor :stay_awake
  attr_accessor :start_on_login
  attr_accessor :allow_remote

  def self.sharedController
    unless @sharedInstance
      @sharedInstance = self.alloc.initWithNibName("PreferencesGeneral", bundle:nil)
    end
    @sharedInstance
  end

  def identifier
      PrefsToolbarItemGeneral
  end

  def title
      "Settings"
  end

  def image
      NSImage.imageNamed('general')
  end

  def awakeFromNib
    @allow_remote.state = App.global.token_model.allow_remote || false
    @launchController ||= LaunchAtLoginController.alloc.init
    @start_on_login.state = @launchController.launchAtLogin
    @stay_awake.state = App.stay_awake?
  end

  def setAllowRemote(sender)
    App.global.token_model.allow_remote = self.allow_remote.state #App.global.token_model.allow_remote == 0 ? 1 : 0
    ApplicationController.singleton.save
    @set_remote ||= Dispatch::Queue.new('set_remote')
    @set_remote.async do
      Logger.debug 'setting auth'
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

  def setStayAwake(sender)
    NSUserDefaults.standardUserDefaults.setBool(self.stay_awake.state == 1, forKey: 'stay_awake')
    ApplicationController.singleton.saveSettings
    ApplicationController.singleton.setConnectorState
  end

end
