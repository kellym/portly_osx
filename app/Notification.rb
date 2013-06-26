#
#  Notification.rb
#  port
#
#  Created by Kelly Martin on 3/7/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class Notification
    def initialize(title)
        @center = NSUserNotificationCenter.defaultUserNotificationCenter
        @notification = NSUserNotification.alloc.init
        @notification.title = title
        @center.delegate = self
    end
    
    def send(text)
        @notification.informativeText = text
        @center.scheduleNotification(@notification)
    end
    
    def userNotificationCenter(center, shouldPresentNotification:notification)
        true
    end
end