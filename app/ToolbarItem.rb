class ToolbarItem < NSView

  attr_accessor :title
  attr_accessor :sender
  attr_accessor :action
  attr_accessor :target

  def drawRect(dirtyRect)
    paragraphStyle = NSParagraphStyle.defaultParagraphStyle.mutableCopy
    paragraphStyle.setAlignment NSCenterTextAlignment
    font = NSFont.fontWithName 'Lucida Grande', size: 11
    attributes = NSDictionary.dictionaryWithObjects(
      [ paragraphStyle, font], forKeys: [NSParagraphStyleAttributeName, NSFontAttributeName] )

    mystr = @title
    #strFrame = [ [ 20, 20 ], [ 20, 20 ]]
    mystr.drawInRect NSMakeRect(0, 4, 55, 15), withAttributes: attributes
  end

  def validate
    #self.menuFormRepresentation.setEnabled true
    #self.label = self.menuFormRepresentation.title
    Logger.debug 'validating'
  end

  def mouseDown(event)
    if self.target.respondsToSelector self.action
      NSApp.sendAction(self.action, to: self.target, from: self.sender)
    end
  end

end
