class NSApplication

  alias_method :origSendEvent, :sendEvent
  def sendEvent(event)
    if event.type == NSKeyDown
      if (event.modifierFlags & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask
        if (event.charactersIgnoringModifiers.isEqualToString "x")
          if (self.sendAction "cut:", to:nil, from:self)
            return
          end
        elsif (event.charactersIgnoringModifiers.isEqualToString "c")
          if (self.sendAction "copy:", to:nil, from:self)
            return
          end
        elsif (event.charactersIgnoringModifiers.isEqualToString "v")
          if (self.sendAction "paste:", to:nil, from:self)
            return
          end
        elsif (event.charactersIgnoringModifiers.isEqualToString "z")
          if (self.sendAction "undo:", to:nil, from:self)
            return
          end
        elsif (event.charactersIgnoringModifiers.isEqualToString "a")
          if (self.sendAction "selectAll:", to:nil, from:self)
            return
          end
        end
      elsif (event.modifierFlags & NSDeviceIndependentModifierFlagsMask) == (NSCommandKeyMask | NSShiftKeyMask)
        if (event.charactersIgnoringModifiers.isEqualToString "Z")
          if (self.sendAction "redo:", to:nil, from:self)
            return
          end
        end
      end
    end
    origSendEvent event
  end

end

