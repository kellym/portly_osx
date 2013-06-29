#
#  StreamDelegate.rb
#  port
#
#  Created by Kelly Martin on 4/8/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


class Stream
    attr_accessor :socket

    def initialize
        @socket_queue = Dispatch::Queue.new('socket.connection')
        @socket_action = Dispatch::Queue.new('socket.action')

        @timeout_max = 15
        startSocket
        @data_queue = []
    end

    def online?
      @socket_online
    end

    def startSocket
        @socket_online = true
        @initConnector = "EHLO:#{App.global.token}"
        @initInput = @initOutput = true
        Logger.debug "Starting Secure Socket on #{App.socket[:host]}:#{App.socket[:port]} with connection: #{@initConnector}"
        NSLog('test message')
        @socket = SocketStream.alloc.initWithHost App.socket[:host], port:App.socket[:port]
        @socket.open(self, output:self)
        Logger.debug "Socket Opened"
        @timeout = 0
        self.performSelectorInBackground("startConnection:", withObject: @socket)
        #Dispatch::Queue.main.async do
        #  sleep 5
        #  Logger.debug "has bytes: #{@socket.inputStream.hasBytesAvailable}"
#
#          sendData("test data")
#        end
    end

    def startConnection(obj)
      while obj.outputStream.streamStatus != 2 || obj.inputStream.streamStatus != 2
        sleep 0.01
      end
      publish_as_online
      setup_output
      read_loop
    end

    def read_loop
      while !@socket.inputStream.hasBytesAvailable
        sleep 0.1
      end
      Logger.debug '#read_loop data available'
      handle_input
      read_loop
    end

    def closeSocket
        Logger.debug "Closing Secure Socket"
        @socket_online = false
        @socket.close if @socket
    end

    def stream(theStream, handleEvent:streamEvent)
      if theStream == @socket.inputStream
        Logger.debug 'input data'
        handleInput(streamEvent)
      else
        Logger.debug 'output data'
        handleOutput(streamEvent)
      end
    end

    def retrySocket
      self.performSelectorInBackground('retrySocketInBackground:', withObject: nil)
    end

    def retrySocketInBackground(obj=nil)
      Logger.debug "Retrying Secure Socket"
      closeSocket
      sleep 5
      startSocket
    end

    def handleInput(streamEvent)
      Logger.debug '#handleInput'
        case streamEvent
        when NSStreamEventOpenCompleted
            Logger.debug "we're loaded"
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
            handle_input
        end
    end

    def handle_input
      Logger.debug 'Handling input.'
      @timeout = 0
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

    def publish_as_online
      if @initConnector
        Logger.debug 'send initial connector data'
        sendData @initConnector
        @initConnector = nil
        @data_queue.each { |msg|
            sendData msg
        }
        @data_queue = []
        App.global.connectors.each { |c| c.publish_state(true) }
      end

    end

    def setup_output
      if @initOutput
          Logger.debug 'keepalive-output'
          #if @socket.keepOutputAlive
          #  Logger.debug 'keepalive-output done'
            @initOutput = nil
            queuePing
            Logger.debug '#setup_output done'
          #else
          #  Logger.debug 'keepalive-output failed'
          #  retrySocket
          #end
      end
    end

    def queuePing
      @socket_queue.async do
          if @socket_online
              if @timeout >= @timeout_max
              #    closeSocket
              #    startSocket
              else
                  sendData "\n"
                  sleep 5
                  queuePing
              #    Logger.debug 'Ping'
              #    queuePing
              end
          end
          #sleep 5
      end
    end

    def handleOutput(streamEvent)
        case streamEvent
        when NSStreamEventOpenCompleted
          setup_output
        when NSStreamEventHasSpaceAvailable
          publish_as_online
        end
    end

    def triggerAction(data)
      Logger.debug 'triggering action'
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
        Logger.debug "writing data: #{data}"
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
        Logger.debug 'done writing ^'
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
