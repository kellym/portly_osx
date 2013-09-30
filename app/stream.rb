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
        #@socket_action = Dispatch::Queue.new('socket.action')

        @action = [
          'plan',
          'signout',
          'connect',
          'kill',
          'update',
          'create',
          'destroy',
          'auths'
        ]

        @timeout_max = 15

        #@socket_action.async do
        @sock = Sock.alloc.initWithHost App.socket[:host], port: App.socket[:port]
        #end

        startSocket
        #self.performSelectorInBackground("queuePing", withObject:nil)
        queuePing
        @data_queue = []
    end

    def online?
      @socket_online
    end

    def startSocket
        Logger.debug "Starting Secure Socket on #{App.socket[:host]}:#{App.socket[:port]} with connection"
        @socket = SocketStream.alloc.initWithHost App.socket[:host], port:App.socket[:port]
        if @socket.open(self, output:self)
          @socket_online = true
          @initConnector = "EHLO:#{App.global.token}"
          @initInput = @initOutput = true
          Logger.debug "Socket Opened"
          @timeout = 0
        else
          retrySocket
        end
    end

    def closeSocket
        Logger.debug "Closing Secure Socket"
        @socket_online = false
        @socket.close if @socket
    end

    def stream(theStream, handleEvent:streamEvent)
      if theStream == @socket.inputStream
        #Logger.debug 'input data'
        handleInput(streamEvent)
      else
        #Logger.debug 'output data'
        handleOutput(streamEvent)
      end
    end

    def retrySocket
      return unless @socket_online
      @socket_online = false
      self.performSelectorInBackground("retrySocketQueue", withObject:nil).release
      #retrySocketQueue
    end

    def retrySocketQueue
        Logger.debug "Retrying Secure Socket"
        closeSocket
        #@sock.port = App.socket[:port]
        #@sock.host = App.socket[:host]
        while !@sock.connect
          sleep 1
        end
        #Dispatch::Queue.main.async do
          startSocket
        #end
    end

    def handleInput(streamEvent)
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
        Logger.debug "SOCKETSTREAM OFFLINE (A)"
        retrySocket
      when NSStreamEventErrorOccurred
        #Logger.debug @socket.inputStream.streamError.localizedDescription
        Logger.debug "something happened, so let's start over."
        Logger.debug "SOCKETSTREAM OFFLINE (B)"
        retrySocket
      when NSStreamEventHasBytesAvailable
        @timeout = 0
        @socket.handleInputAndTriggerAction
      end
    end

    def publish_as_online
      if @initConnector
        Logger.debug 'send initial connector data'
        @socket.sendData @initConnector
        @initConnector = nil
        @data_queue.each { |msg|
            @socket.sendData msg
        }
        @data_queue = []
        App.global.connectors.each { |c| c.publish_state(true) }
      end

    end

    def setup_output
      if @initOutput
          Logger.debug 'keepalive-output'
          if @socket.keepOutputAlive
            Logger.debug 'keepalive-output done'
            @initOutput = nil
            Logger.debug '#setup_output done'
          else
            Logger.debug 'keepalive-output failed'
            retrySocket
          end
      end
    end

    def queuePing
      @socket_queue.async do
        while(true) do
          if @socket_online
            if @timeout >= @timeout_max
              Logger.debug "retry socket"
              retrySocket
            elsif @socket
              #string = "\n"
              #Logger.debug "PING"
              @socket.sendPing
            else
              #@socket = SocketStream.alloc.initWithHost App.socket[:host], port:App.socket[:port]
              retrySocket
            end
          elsif !@socket_online
            Logger.debug "PING: Something is wrong."
            retrySocket
          end
          sleep 5
        end
      end
    end

    def handleOutput(streamEvent)
        case streamEvent
        when NSStreamEventOpenCompleted
          setup_output
        when NSStreamEventHasSpaceAvailable
          publish_as_online
        when NSStreamEventErrorOccurred
            #Logger.debug @socket.outputStream.streamError.localizedDescription
            Logger.debug "something happened, so let's start over."
            retrySocket
        end
    end

    def triggerAction(parts)
      case parts[0]
      when @action[0]
        App.global.plan_type = parts[1]
      when @action[1]
        ApplicationController.singleton.signOut
      when @action[2]
        return unless App.global.token_model.allow_remote
        id, connection_string, tunnel_string = parts[1].split "|"
        m = App.global.connectors.select { |c| c.connector_id == id.to_i }.first
        m.event_connect(connection_string, tunnel_string) if m
      when @action[3]
        return unless App.global.token_model.allow_remote
        m = App.global.connectors.select { |c| c.connector_id == parts[1].to_i }.first
        m.force_disconnect if m
      when @action[4]
        return unless App.global.token_model.allow_remote
        m = App.global.connectors.select { |c| c.connector_id == parts[1].to_i }.first
        m.update if m
      when @action[5]
        return unless App.global.token_model.allow_remote
        Logger.debug 'loading all'
        ConnectorMonitor.load_all
      when @action[6]
        return unless App.global.token_model.allow_remote
        m = App.global.connectors.select { |c| c.connector_id == parts[1].to_i }.first
        if m
            m.force_disconnect if m.running?
            m.destroy_model
        end
      when @action[7]
        return unless App.global.token_model.allow_remote
        m = App.global.connectors.select { |c| c.connector_id == parts[1].to_i }.first
        m.getAuthUsers if m
      end
    end

    def send(msg)
        if @initConnector
            # we are waiting to send data, so queue it for now.
            @data_queue << msg
        else
            @socket.sendData(msg)
        end
    end

end
