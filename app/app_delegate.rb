class AppDelegate
  def applicationDidFinishLaunching(notification)
    buildWindow
  end

  def buildWindow
    ApplicationController.new.awakeFromNib
  end
end
