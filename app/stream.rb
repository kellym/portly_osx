#
#  StreamDelegate.rb
#  port
#
#  Created by Kelly Martin on 4/8/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class Stream

    def initialize
        @socket_queue = Dispatch::Queue.new('socket.connection')
        @socket_action = Dispatch::Queue.new('socket.action')

        @timeout_max = 15
        startSocket
        @data_queue = []
    end

    def startSocket
        @socket_online = true
        @initConnector = "EHLO:#{App.global.token}"
        @initInput = @initOutput = true
        @socket = SocketStream.alloc.initWithHost App.socket[:host], port:App.socket[:port]

        @socket.open(self, output:self)
        @timeout = 0
    end

    def closeSocket
        @socket_online = false
        @socket.close if @socket
    end
    def stream(theStream, handleEvent:streamEvent)
        if theStream == @socket.inputStream
            handleInput(streamEvent)
        else
            handleOutput(streamEvent)
        end
    end

    def retrySocket
      @socket_retry_queue ||= Dispatch::Queue.new('socket.connection.retry')
      closeSocket
      @socket_retry_queue.sync { Dispatch::Queue.main.async { startSocket }; sleep 5 }
    end

    def handleInput(streamEvent)
        case streamEvent
        when NSStreamEventOpenCompleted
            #Logger.debug "we're loaded"
            if @initInput
                Logger.debug 'doing keepalive-input'
                if @socket.keepInputAlive
                  Logger.debug 'done with keepalive-input'
                  @initInput = nil
                else
                  Logger.debug 'could not perform keepalive-input'
                  retrySocket
                end
            end
        when NSStreamEventEndEncountered
            Logger.debug "we're done, but we need to reconnect."
            closeSocket
            startSocket
        when NSStreamEventErrorOccurred
            Logger.debug @socket.inputStream.streamError.localizedDescription
            Logger.debug "something happened, so let's start over."
            retrySocket
        when NSStreamEventHasBytesAvailable
            Logger.debug 'data available'
            buf = Pointer.new('c', 1024)
            data = ''
            while @socket.inputStream.hasBytesAvailable do
                len = @socket.inputStream.read(buf, maxLength:1024)
                if len > 0
                    (0..len-1).each { |i| data << buf[i].chr }
                end
            end
            triggerAction(data)
        end
    end

    def queuePing
      @socket_queue.async do
          if @socket_online
              if @timeout >= @timeout_max
                  closeSocket
                  startSocket
              else
                  sendData "\n"
                  Logger.debug 'Ping'
                  queuePing
              end
          end
          sleep 5
      end
    end

    def handleOutput(streamEvent)
        case streamEvent
        when NSStreamEventOpenCompleted
            if @initOutput
                Logger.debug 'keepalive-output'
                if @socket.keepOutputAlive
                  Logger.debug 'keepalive-output done'
                  @initOutput = nil
                  queuePing
                else
                  Logger.debug 'keepalive-output failed'
                  retrySocket
                end
            end
        when NSStreamEventHasSpaceAvailable
            if @initConnector
                Logger.debug 'send initial connector data'
                #data = NSMutableData.dataWithBytes(@initConnector.pointer, length: @initConnector.length)
                data = @initConnector.dataUsingEncoding(NSUTF8StringEncoding)
                readBytes = data.mutableBytes
                #readBytes += byteIndex; // instance variable to move pointer
                data_len = data.length
                #unsigned int len = ((data_len - byteIndex >= 1024) ?
                #                    1024 : (data_len-byteIndex));
                #uint8_t buf[len];
                buf = Pointer.new('c', data_len)

                len = @socket.outputStream.write(data, maxLength:data_len)
                @initConnector = nil
                #byteIndex += len;
                @data_queue.each { |msg|
                    sendData msg
                }
                @data_queue = []
                App.global.connectors.each { |c| c.publish_state(true) }
            end
        end
    end

    def triggerAction(data)
        @timeout = 0
        @data = data.to_s
        Logger.debug @data
        return unless App.global.token_model.allow_remote
        @socket_action.async do
            case @data
            when /^connect:(.*)$/
                id, connection_string, tunnel_string = $1.split "|"
                m = App.global.connectors.select { |c| c.connector_id == id.to_i }.first
                m.event_connect(connection_string, tunnel_string) if m
            when /^kill:(.*)$/
                m = App.global.connectors.select { |c| c.connector_id == $1.to_i }.first
                m.force_disconnect if m
            when /^update:(.*)$/
                m = App.global.connectors.select { |c| c.connector_id == $1.to_i }.first
                m.update if m
            when /^create:(.*)$/
                Logger.debug 'loading all'
                ConnectorMonitor.load_all
            when /^destroy:(.*)$/
                m = App.global.connectors.select { |c| c.connector_id == $1.to_i }.first
                if m
                    m.force_disconnect if m.running?
                    m.destroy_model
                end
            when /^auths:(.*)$/
                m = App.global.connectors.select { |c| c.connector_id == $1.to_i }.first
                m.getAuthUsers if m
            end
        end

        #Logger.debug data
        #sleep 2
        #sendData data
    end

    def sendData(data)
        return unless @socket.outputStream
        max_bytes = 1024
        data = data.dataUsingEncoding(NSUTF8StringEncoding)
        readBytes = data.mutableBytes
        byteIndex = 0
        data_len = data.length
        while (byteIndex < data_len) do
            len = (data_len - byteIndex >= max_bytes) ? max_bytes : (data_len-byteIndex)
            buf = Pointer.new('c', len)
            bytesRead = @socket.outputStream.write(data, maxLength:len)
            byteIndex += len
        end
    end

    def send(msg)
        if @initConnector
            # we are waiting to send data, so queue it for now.
            @data_queue << msg
        else
            sendData(msg)
        end
    end

end
