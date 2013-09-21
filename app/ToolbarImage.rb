class ToolbarImage < NSImageView

  attr_accessor :sender

  def mouseDown(event)
    if self.target.respondsToSelector self.action
      NSApp.sendAction(self.action, to: self.target, from: self.sender)
    end
  end

end
