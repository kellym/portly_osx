class AppDelegate < NSObject

  attr_accessor :applicationController
  attr_accessor :panelController
  #attr_accessor :menubarController

  def applicationDidFinishLaunching(notification)
    buildWindow
  end

  def buildWindow
    @applicationController ||= ApplicationController.new
    @applicationController.panel = self.panelController
    @applicationController.awakeFromNib
  end

  def observeValueForKeyPath(keyPath, ofObject:object, change:change, context:context)
    if keyPath == "hasActivePanel"
      self.applicationController.hasActiveIcon = self.panelController.hasActivePanel
    end
  end

  def applicationDidResignActive(notification)

  end

  def userNotificationCenter(center, shouldPresentNotification: notification)
    true
  end

  def togglePanel(sender)
    Logger.debug 'button clicked'
    @applicationController.hasActiveIcon = !@applicationController.hasActiveIcon
    self.panelController.triggerActivePanel @applicationController.hasActiveIcon
  end

  def addTunnel(sender)
    @applicationController.addTunnel(sender)
  end

  def panelController
    unless @panelController
        @panelController = PanelController.alloc.initWithDelegate self
        @panelController.addObserver self, forKeyPath: "hasActivePanel", options:0, context: nil
    end
    @panelController
  end

  def statusItemViewForPanelController(controller)
    return self.applicationController.statusItemView
  end
end
