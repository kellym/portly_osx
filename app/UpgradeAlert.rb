class UpgradeAlert

    def handleAlertSuccessResponse
      NSWorkspace.sharedWorkspace.openURL NSURL.URLWithString(App.upgrade_url)
    end

    def handleAlertIgnoreResponse

    end
end
