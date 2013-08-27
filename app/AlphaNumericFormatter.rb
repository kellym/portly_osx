class AlphaNumericFormatter < NSFormatter

  def handler
    @handler ||= App.free? ? /[^0-9a-zA-Z\-]/ : /[^0-9a-zA-Z\-\*]/
  end

  def stringForObjectValue(object)
    object.gsub(handler, '')
  end

  def getObjectValue(object, forString: string, errorDescription: error)
    object[0] = string.gsub(handler, '')
    true
  end

  def isPartialStringValid( partialString, newEditingString: newString, errorDescription: error)
    if partialString.match(handler)
      true
    else
      newString[0] = partialString.gsub(handler, '')
      false
    end
  end

end
