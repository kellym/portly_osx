#
#  logger.rb
#  port
#
#  Created by Kelly Martin on 5/31/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class Logger

    def self.debug data
        if App.development? || App.debug?
            puts data
        end
    end

end