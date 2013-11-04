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

        @initConnector = "EHLO:#{App.global.token}"
        @socket = SocketStream.alloc.initWithHost App.socket[:host], port: App.socket[:port], delegate: self
        @socket.start

        @data_queue = []
    end

    def startSocket
      @initConnector = "EHLO:#{App.global.token}"
      @socket.start if !@socket.isInitialized
    end
    def closeSocket
      @socket.close if @socket && @socket.isInitialized
    end

    def online?
      @socket.isInitialized
    end

    def setup_input
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

    def publish_as_online
        Logger.debug 'send initial connector data'
        @socket.sendData @initConnector
        @data_queue.each { |msg|
            @socket.sendData msg
        }
        @data_queue = []
        App.global.connectors.each { |c| c.publish_state(true) }
    end

    def triggerAction(parts)
      case parts[0]
      when @action[0]
        App.global.plan_type = parts[1]
      when @action[1]
        ApplicationController.singleton.signOut
      when @action[2]
        return unless App.global.token_model.allow_remote == 1
        id, connection_string, tunnel_string = parts[1].split "|"
        m = App.global.connectors.select { |c| c.connector_id == id.to_i }.first
        m.event_connect(connection_string, tunnel_string) if m
      when @action[3]
        return unless App.global.token_model.allow_remote == 1
        m = App.global.connectors.select { |c| c.connector_id == parts[1].to_i }.first
        m.force_disconnect if m
      when @action[4]
        return unless App.global.token_model.allow_remote == 1
        m = App.global.connectors.select { |c| c.connector_id == parts[1].to_i }.first
        m.update if m
      when @action[5]
        return unless App.global.token_model.allow_remote == 1
        Logger.debug 'loading all'
        ConnectorMonitor.load_all
      when @action[6]
        return unless App.global.token_model.allow_remote == 1
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
        if !@socket.isInitialized
            # we are waiting to send data, so queue it for now.
            @data_queue << "\n#{msg}"
        else
          Logger.debug "Sending: #{msg}"
            @socket.sendData("\n#{msg}")
        end
    end

end
