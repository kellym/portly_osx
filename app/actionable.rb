class Actionable < NSScriptCommand

  def performDefaultImplementation

    args = self.evaluatedArguments
    string = ''
    if args.count
      string = args.valueForKey ''
    else
      return 0
    end
    App.global.connectors.each do |c|
      if c.subdomain == string
        c.connect
        return c.port
      end
    end

  end

end
