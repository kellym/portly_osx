#
#  Connector.rb
#  port
#
#  Created by Kelly Martin on 3/6/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#

class ConnectorMonitor

    attr_accessor :task
    attr_accessor :connection_string
    attr_accessor :connector_id
    attr_accessor :subdomain
    attr_accessor :cname
    attr_accessor :start_on_boot
    attr_accessor :auth_type
    attr_accessor :socket_type
    attr_accessor :server_port
    attr_accessor :server_host

    attr_accessor :model
    attr_accessor :entity
    attr_accessor :auth_users
    attr_accessor :thread

    attr_accessor :timeout
    attr_accessor :reconnect

    def initialize(data)
        @host = data.host
        @port = data.port
        @path = data.path

        @modes = [NSEventTrackingRunLoopMode, NSDefaultRunLoopMode]
        set_connection_string
        @connector_id = data.connector_id
        @subdomain = data.subdomain
        @cname = data.cname
        @start_on_boot = (data.start_on_boot == 1) && !App.free?
        @_init = @start_on_boot
        @auth_type = data.auth_type
        @nickname = data.nickname
        @socket_type = data.socket_type || 'http'
        @server_port = data.server_port
        @server_host = data.server_host
        @hide_wordpress_alert = data.hide_wordpress_alert == 1
        @pref = nil
        @model = data
        @online = false
        @retry_seconds = 5
        @timeout = 0
        @reference = data.connector_id
        @auth_users = []
        @awaiting_reconnect = false
        @current_port_status = true
        @check_port_status = false
        #getAuthUsers

        @sock = Sock.alloc.initWithHost @host, port: @port
        @sock.delegate = self

        #self.performSelectorOnMainThread("create_row_and_monitor", withObject: nil, waitUntilDone: false)
        Dispatch::Queue.main.async do
          create_row_and_monitor
        end
        menu_item

        App.global.connectors << self

        @published_state = nil
        #publish_state
        self.performSelectorInBackground("publish_state", withObject: nil)

        self
    end

    def create_row_and_monitor
      while(ApplicationController.singleton.panel.isAnimating) do
      end
      @row = ApplicationController.singleton.panel.addRowWithDelegate self
      begin
        self.performSelectorInBackground("monitor_port:", withObject: @retry_seconds)
      rescue
        Logger.debug "ERROR ON THE MONITOR_PORT THREAD"
        retry
      end
    end

    def online?
        @online
    end

    def resetTimeout
      @timeout = 0
    end

    def disableReconnect
      @reconnect = false
    end

    def publish_state(force = false)
      current_state = port_open?
      if (current_state != @published_state) || force
        #@publish_state_queue ||= Dispatch::Queue.new("publish_state:#{@connector_id}")
        #@publish_state_queue.async do
          while !ApplicationController.singleton.socket do
          #  sleep 1
          end
          #Dispatch::Queue.main.async do
            Logger.debug "STATE:#{@connector_id}:#{current_state ? 'on' : 'off'}"
            ApplicationController.singleton.socket.send("STATE:#{@connector_id}:#{current_state ? 'on' : 'off'}")
          #end
        #end
        @published_state = current_state
      end
    end

    def set_port_online
        connect if @_init
        ##Logger.debug "timeout: #{@timeout}"
        reconnect if running? && @timeout > @retry_seconds * 2
        return if @current_port_status == true
        @current_port_status = true

        self.performSelectorInBackground("publish_state", withObject: nil)
        #Logger.debug "port is running: #{@port}"
        update_menu_item( online: running? )
        Dispatch::Queue.main.async do
          @row.setActive if @row
        end
        @pref.imageView.image = (running? ? App.online : App.offline) if @pref
    end


    def set_port_offline
        return if @current_port_status == false
        @current_port_status = false

        #publish_state
        self.performSelectorInBackground("publish_state", withObject: nil)

        Dispatch::Queue.main.async do
          @row.setInactive if @row
        end
        @pref.imageView.image = App.disabled if @pref
        if running? || @hide_reconnect
            #Logger.debug 'Port is closed but it is still running.'
            disconnect(true)
            queue_reconnect
        elsif !@awaiting_reconnect
          #@menu_item.setEnabled false
        end

    end

    def connection_string_with_nickname
      (@nickname && @nickname != "") ? "#{@connection_string} (#{@nickname})" : @connection_string
    end

    def connection_string=(connection_string)
        data = ConnectorMonitor.parse_connection_string(connection_string)
        @host = data[:host]
        @port = data[:port]
        @nickname = data[:nickname]
        @path = data[:path]
    end

    def self.parse_connection_string(connection_string)
        data = {}
        connection_string = connection_string.gsub(/^[a-z]{3,6}:\/\//, '')
        if connection_string.index('(')
          first = connection_string.index('(')
          last = connection_string.rindex(')') || connection_string.length
          data[:nickname] = connection_string[first+1..last-1]
          connection_string = connection_string[0..first]
        end
        if connection_string.index('/')
          first = connection_string.index('/')
          data[:path] = connection_string[first..connection_string.length-1]
          connection_string = connection_string[0..first-1]
        end

        if connection_string =~ /^[0-9]*$/
            Logger.debug 'only port'
            data[:host] = 'localhost'
            data[:port] = connection_string.to_i
        elsif connection_string =~ /\:/
            Logger.debug 'both'
            pos = connection_string.rindex(':')
            data[:host], data[:port] =  connection_string[0...pos], connection_string[pos+1..-1]
            data[:port] = data[:port].to_i
        else
            Logger.debug 'only host'
            data[:host] = connection_string
            data[:port] = 80
        end
        data
    end

    def self.parse_socket_type(type)
      case type
      when 'Raw TCP Socket'
        @socket_type = 'tcp'
      else
        @socket_type = 'http'
      end
      @socket_type
    end

    # TODO: on creation, it autoboots but acts a bit funky and keeps disconnecting
    def self.create(opts={})
        opts[:socket_type] = self.parse_socket_type(opts[:socket_type])

        data = self.parse_connection_string(opts[:connection_string]).merge({
            'subdomain' => opts[:subdomain],
            'cname' => opts[:cname],
            'socket_type' => opts[:socket_type],
            'auth_type' => opts[:auth_type],
            'computer_name' => NSHost.currentHost.localizedName,
            'publish' => 'false'
        })
        res = App.api_post("/connectors",data)
        if res
            result = res
            Logger.debug result.inspect
            opts['id'] = result['id']
            opts.delete :connection_string
            opts[:host] = data[:host]
            opts[:port] = data[:port]
            opts[:path] = data[:path]
            opts[:nickname] = data[:nickname]
            opts[:server_port] = result['server_port']
            opts[:server_host] = result['server_host']
            ConnectorMonitor.create_model(opts)
        end
    end

    def self.create_model(data)
        Logger.debug  'model:'
        Logger.debug data.inspect
        model = NSEntityDescription.insertNewObjectForEntityForName "Connector", inManagedObjectContext:ApplicationController.singleton.managedObjectContext
        model.connector_id = data['id'].to_i
        data.each do |k,v|
            model.send "#{k}=".to_sym, v unless %w(id auths).include?(k)
            Logger.debug "#{k}=#{v}"
        end
        model.reference = Time.now.to_i
        Logger.debug model.valueForKey('connector_id')
        Logger.debug model.valueForKey('reference')
        Logger.debug model.valueForKey('host')
        ApplicationController.singleton.save
        c = ConnectorMonitor.new(model)
        ConnectorsViewController.sharedController.connectors_list.reloadData if ConnectorsViewController.sharedController.connectors_list
        return c # we need to return this
    end

    def save
        @reconnect_after_save = false
        if online? && ((@model.host != @host) || @model.port != @port.to_i)
            @reconnect_after_save = true
            set_port_offline
            event_disconnect(true)
        end
        save_model
        @save_connector_queue ||= Dispatch::Queue.new("save_connector:#{@connector_id}")
        set_connection_string
        set_menu_item_title
        set_pref_title
        Dispatch::Queue.main.async do
          if port_open?
            @row.setActive if @row
          else
            @row.setInactive if @row
          end
        end
        ConnectorsViewController.sharedController.connectors_list.reloadData() if ConnectorsViewController.sharedController.connectors_list
        @save_connector_queue.async do
            data = {
                'host' => @model.host,
                'port' => @model.port,
                'subdomain' => @model.subdomain,
                'nickname' => @model.nickname,
                'cname' => @model.cname,
                'path' => @model.path,
                'auth_type' => @model.auth_type,
                'socket_type' => @model.socket_type,
                'computer_name' => NSHost.currentHost.localizedName,
                'publish' => 'false'
            }
            App.api_put("/connectors/#{@connector_id}", data)
            if !online? && @reconnect_after_save && port_open?
                event_connect(@event_connection_string, @event_tunnel_string)
            end
            @reconnect_after_save = false
        end
    end

    def save_model
      if @model
        @model.start_on_boot = @start_on_boot
        @model.hide_wordpress_alert = @hide_wordpress_alert
        @model.host = @host
        @model.port = @port
        @model.auth_type = @auth_type
        @model.cname = @cname
        @model.nickname = @nickname
        @model.path = @path
        @model.socket_type = @socket_type
        @model.connector_id = @connector_id
        @model.subdomain = @subdomain
      end
      ApplicationController.singleton.save
    end

    def self.all
        connectors = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Connector', andPredicate:nil, options:{})
        #Logger.debug connectors.count
        connectors
    end

    def self.load_all
      if App.global.connectors.size == 0
        Logger.debug "LOADING THIS MANY CONNECTORS: #{self.all.size}"
          self.all.each do |connector|
              ConnectorMonitor.new(connector)
          end
      end
      # now that they're all loaded, let's download the list and synchronize. we may have to destroy old connectors
      Logger.debug 'getting all connectors'
      res = App.api_get("/connectors")
      connectors = res ? res : []
      synchronized = []
      connectors.each do |connector|
          c = App.global.connectors.select { |c| c.connector_id == connector['id'] }.first
          if c
              c.synchronize_with(connector)
              synchronized << c
          else
              Logger.debug 'creating'
              Logger.debug connector.inspect
              synchronized << ConnectorMonitor.create_model(connector)
          end
      end
      (App.global.connectors - synchronized).each do |deleted_connector|
          Logger.debug 'destroying'
          Logger.debug deleted_connector.inspect
          deleted_connector.disconnect
      end
    end

    def update
      @update_sync ||= Dispatch::Queue.new("update_sync:#{@connector_id}")
      @update_sync.async do
        res = App.api_get("/connectors/#{@connector_id}")
        self.synchronize_with(res) if res
      end
    end

    def synchronize_with(data)
      @connector_id = data['id']
      @auth_users = data['auths'] if data.has_key?('auths')
      should_reconnect = false
      if online? && ( (data.has_key?('host') && @host!=data['host']) || (data.has_key?('port') && @port.to_i != data['port'].to_i) )
        should_reconnect = true
        event_disconnect(true) # hide the updated status
      end
      data.each do |k,v|
        instance_variable_set(:"@#{k}",v) unless %w(id auths).include?(k)
      end
      save_model
      set_connection_string
      set_menu_item_title
      set_pref_title
      ConnectorsViewController.sharedController.connectors_list.reloadData() if ConnectorsViewController.sharedController.connectors_list
      if should_reconnect
        event_connect(@event_connection_string, @event_tunnel_string)
      end
    end

    def update_menu_item(state={})

      Dispatch::Queue.main.async do
        if state[:online]
          if @row
            @row.activityButton.title = "Stop"
            @row.setOnline
          end
          @pref.imageView.image = App.online if @pref
        else
          if @row
            @row.setOffline
          end
          @pref.imageView.image = App.offline if @pref
        end
      end
    end

    def menu_item
      return @menu_item if @menu_item
      @menu_item = NSMenuItem.new
      set_menu_item_title
      @menu_item
    end

    def set_connection_string
      @connection_string = "#{@host}:#{@port}#{@path}"
    end

    def set_menu_item_title
      Dispatch::Queue.main.async do
        if @row
          @row.setTitle((@model.nickname && @model.nickname != '') ? @model.nickname : @connection_string)
          @row.subtitle = domain_string
        end
      end
    end

    def http
      if @socket_type == 'http' || @socket_type == ''
        App.free? || @cname.to_s != '' ? 'http://' : 'https://'
      else
        ''
      end
    end

    def domain_string
      if @socket_type == 'http' || @socket_type == ''
        if @cname.to_s == ''
          if @subdomain.to_s == ''
            App.global.suffix
          else
            "#{@subdomain}-#{App.global.suffix}"
          end
        else
          @cname
        end
      else
        "#{@server_host}:#{@server_port}"
      end
    end

    def pref tableView
      #return @pref if @pref
      @pref = tableView.makeViewWithIdentifier "ConnectorPref", owner:self
      set_pref_title
      @pref.imageView.image = port_open? ? (running? ? App.online : App.offline) : App.disabled
      #Dispatch::Queue.main.async do
      #  if running?
      #    @row.activityButton.title = "Stop"
      #    @row.setOnline
      #  else
      #    @row.setOffline
      #  end
      #  if port_open?
      #    @row.setActive
      #  else
      #    @row.setInactive
      #  end
      #end
      @pref
    end
    def set_pref_title
      @pref.textField.stringValue = @connection_string if @pref
    end

    def copyLink(from)
      pasteboard = NSPasteboard.generalPasteboard
      pasteboard.clearContents
      pasteboard.writeObjects ["#{http}#{domain_string}"]
      ApplicationController.singleton.panel.setHasActivePanel false
    end

    def toggleState(row)
      Logger.debug 'Toggling state.'
      if @awaiting_reconnect
        @awaiting_reconnect = false
        disconnect
        ApplicationController.singleton.panel.setHasActivePanel false
      else
        if online?
          disconnect
          ApplicationController.singleton.panel.setHasActivePanel false
        else
          connect
        end
      end
    end

    def get_reconnect_default
      App.free? ? false : true
    end

    def connect
      Logger.debug 'Boot.'
      @_init = false
      @attempting_reconnect = false
      return if running?
      @hide_reconnect = false
      @awaiting_reconnect = false
      @reconnect = get_reconnect_default
      @timeout = 0
      @connector_queue ||= Dispatch::Queue.new("#{App.queue_prefix}.ssh_start.#{@reference}")
      @connector_queue.async do
        Logger.debug 'Sending connection data.'
        data = {
          'connector_id' => self.model.valueForKey('connector_id'),
          'publish' => 'false'
        }
        response = App.api_post("/tunnels",data)
        if response
          @response = response
          unless @hide_wordpress_alert
            URLValidator.send "http://#{@connection_string}", delegate: self
          end
          event_connect @response['connection_string'], @response['tunnel_string']
        elsif App.error == 'already_connected'
          event_disconnect
          alert = NSAlert.alertWithMessageText 'Already in Use', defaultButton: nil, alternateButton: nil, otherButton: nil, informativeTextWithFormat: "The domain you are attempting to use is already in use. Please try another."
          alert.beginSheetModalForWindow ApplicationController.singleton.panel.window, modalDelegate: self, didEndSelector: nil, contextInfo: nil
        else
          @awaiting_reconnect = true
          queue_reconnect
        end
      end
    end

    def handleValidationResponse(response, data: data, error: error)
      content = NSString.alloc.initWithData(data, encoding: NSUTF8StringEncoding)
      if content.downcase.index('wp-content/themes')
          @alert = Alert.alloc.init.retain
          @alert.alert 'WordPress Plugin Needed', defaultButton: "Visit Download URL", alternateButton: "Skip This", otherButton: "Remind Me Later", informativeTextWithFormat: "It appears you are running WordPress on this port. Please install the Portly Router plugin for full support.", window: ApplicationController.singleton.window, delegate: self
      end
    end

    def handleAlertSuccessResponse
      NSWorkspace.sharedWorkspace.openURL NSURL.URLWithString(App.install_wordpress_plugin_url)
      @hide_wordpress_alert = true
      self.save_model
      @alert.release
    end

    def handleAlertIgnoreResponse
      @hide_wordpress_alert = true
      self.save_model
      @alert.release
    end

    def handleAlertOtherResponse
      @alert.release
    end

    def event_connect(connection_string, tunnel_string)
      return disconnect if connection_string.to_s == '' || tunnel_string.to_s == ''
      Dispatch::Queue.main.async do
        Logger.debug "STARTING TUNNEL!"
        @event_connection_string = connection_string
        @event_tunnel_string = tunnel_string
        if @socket_type == 'tcp'
          tunnel_string = @server_port
        end
        # create a new task
        Logger.debug "REFERENCE: #{@reference}"
        @task = NSTask.new
        env = NSProcessInfo.processInfo.environment
        @task.setEnvironment({"CID" => @connector_id,"TOKEN" => App.global.token, 'SSH_SOCK_AUTH' => env.objectForKey("SSH_AUTH_SOCK")})
        @task.setLaunchPath("/usr/bin/ssh")
        Logger.debug "\"#{tunnel_string}\" \"#{connection_string}\" #{@connector_id}"
        Logger.debug "Private Key Path: #{App.private_key_path}"
        Logger.debug "Public Key Path: #{App.public_key_path}"
        arr = ["-C", "-2", connection_string, "-o UserKnownHostsFile=\"#{App.public_key_path.gsub('"', '\"')}\"", "-o SendEnv=CID", "-o SendEnv=TOKEN", "-R #{tunnel_string}:#{@host}:#{@port}", "-i", App.private_key_path]
        if @socket_type == 'tcp'
          arr.unshift '-g'
        end
        @task.setArguments(arr)

        Logger.debug "EVENT CONNECT"
        po = NSPipe.new
        p_error = NSPipe.new
        @task.standardOutput = po
        @task.standardError = p_error
        @task.launch

        @error_handle = p_error.fileHandleForReading
        @fh = po.fileHandleForReading

        @error_handle.waitForDataInBackgroundAndNotifyForModes [NSEventTrackingRunLoopMode, NSDefaultRunLoopMode]
        @fh.waitForDataInBackgroundAndNotifyForModes [NSEventTrackingRunLoopMode, NSDefaultRunLoopMode]

        # error handling
        #Logger.debug 'Adding error handling.'
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'receivedError:', name:NSFileHandleDataAvailableNotification, object: @error_handle)

        # regular handling
        NSNotificationCenter.defaultCenter.addObserver(@sock, selector:'receivedPing:', name: NSFileHandleDataAvailableNotification, object: @fh)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'taskTerminated:', name: NSTaskDidTerminateNotification, object: @task)

        Logger.debug 'Connecting to port.'
        @online = true
        if @row
          @row.activityButton.title = "Stop"
          @row.setOnline
        end
        @pref.imageView.image = App.online if @pref
        ApplicationController.singleton.setConnectorState

      end
    end

    def monitor_port(seconds=0)
      @monitor_seconds = seconds
      while(true) do
        #catch(:done) do
          #Logger.debug "monitoring port status of #{@port}"
          if connect_to(@host, @port, 1)
            ##Logger.debug 'set online'
            set_port_online
          else
            #Logger.debug 'set offline'
            set_port_offline
          end
          #Logger.debug "[monitor]"
          #if @check_port_status
          ##  Logger.debug "check port status"
          #  @check_port_status = false
          #  #throw :done
          if @row.nil? || @monitor_seconds.nil?
            #Logger.debug "row or monitor is nil"
            return
          else
            sleep @monitor_seconds # / 100
          end
          @timeout += @monitor_seconds
        #end
      end
    end

    def connect_to(host, port, timeout)
      begin
        #Logger.debug "trying to connect locally to #{host}:#{port}"
        @sock.host = host
        @sock.port = port
        response = @sock.connect #Sock.connect(host, port:port)
        return response
      rescue Exception
        #Logger.debug "ERROR ON THE SOCKET CONNECT"
        false
      end
    end

    def port_open?
        #connect_to(@host, @port, 1)
        @check_port_status = true
        @current_port_status
    end

    def reconnect
        disconnect(true)
        connect unless App.free?
    end

    def running?
      @online
    end

    def isRunning
      if @online && !@attempting_reconnect
        1
      else
        nil
      end
    end

    def queue_reconnect(seconds=nil)
      return if @attempting_reconnect
      unless App.free?
        @attempting_reconnect = true
        #self.performSelectorInBackground('queue_reconnect_in_background:', withObject:seconds)
        @queue_reconnect_queue ||= Dispatch::Queue.new("queue:#{@connector_id}")
        @queue_reconnect_queue.async do
          queue_reconnect_in_background(seconds || @retry_seconds)
        end
      end
    end

    def queue_reconnect_in_background(seconds=nil)
      seconds ||= @retry_seconds
      while(true) do
        #Logger.debug "Retrying in #{seconds} seconds."
        sleep seconds
        if port_open? && @awaiting_reconnect && !online? && ApplicationController.singleton.socket.online?
          #Logger.debug "Port is open again."
          break
        elsif @awaiting_reconnect && !online?
          #Logger.debug "Requeueing connection."
        end
      end
      connect
    end

    def receivedError(notif)
      fh = notif.object
      data = fh.availableData.to_s
      Logger.debug data
      return unless running?
      Logger.debug "continuing on anyway"

      data = data.lines.first || ''
      if data.match(/closed|Killed by signal/)
        Logger.debug "Reconnecting."
      elsif data.match(/Warning/i)
        Logger.debug data
        # just a warning, so continue as usual
      elsif data.match(/failed/) && !port_open?
        Logger.debug "Port isn't open."
        disconnect(true)
        queue_reconnect
      elsif data.match(/No route to host/i)
        Logger.debug "No internet."
        disconnect(true)
        queue_reconnect
      elsif data.match(/Permission|Identity|key/i)
        # the identity/key file has gone bad. redownload
        App.get_keys!
        @reconnect_immediately = true
      else
        Logger.debug "Going to reconnect anyway."
        #disconnect
      end
    end

    def receivedPing(notif)

        fh = notif.object
        #data = fh.availableData.to_s
        data = NSString.alloc.initWithData fh.availableData, encoding: NSUTF8StringEncoding
        @timeout = 0
        #if data['TIMEOUT']
        if data.rangeOfString("TIMEOUT").location == 0


          @reconnect = false
          disconnect(false)
        end
        data.release
        fh.waitForDataInBackgroundAndNotifyForModes(@modes) if running?
    end

    def taskTerminated(notif)
       Logger.debug "Task was terminated."
       disconnect(true)
       if @reconnect_immediately
         @reconnect_immediately = false
         queue_reconnect 0
       else
         queue_reconnect
       end
    end

    def disconnectTimeout
      disconnect(false, false)
      @row.setOffline
    end

    def disconnect(awaiting_reconnect=false, async=true)
      if @awaiting_reconnect && (awaiting_reconnect == false)
        @awaiting_reconnect = false
        event_disconnect(false, async)
      else
        @awaiting_reconnect = awaiting_reconnect
        publish_disconnect(async)
        event_disconnect(false, async)
      end
    end

    def publish_disconnect(async=true)
      Logger.debug 'publishing disconnect'
      if async
        @disconnect_port_queue ||= Dispatch::Queue.new("#{App.queue_prefix}.disconnect.#{@reference}")
        @disconnect_port_queue.async do
          App.api_delete("/tunnels/#{@connector_id}", { 'publish' => false })
        end
      else
        App.api_delete("/tunnels/#{@connector_id}", { 'publish' => false })
      end
    end

    def force_disconnect
      @awaiting_reconnect = false
      event_disconnect
    end

    def event_disconnect(hide_updates = false, async = true)
      Logger.debug 'Disconnecting task.'
      #unless @awaiting_reconnect
      #  unless port_open?
      #    Dispatch::Queue.main.async do
      #      @row.setInactive
      #    end
      #  end
      #end

      NSNotificationCenter.defaultCenter.removeObserver(self, name:NSFileHandleDataAvailableNotification, object: @error_handle)
      NSNotificationCenter.defaultCenter.removeObserver(self, name:NSFileHandleDataAvailableNotification, object: @fh)
      NSNotificationCenter.defaultCenter.removeObserver(self, name:NSTaskDidTerminateNotification, object: @task)

      @task.terminate if running?

      if async
        Dispatch::Queue.main.async do
          set_row_state
        end
      else
        set_row_state
      end

      @pref.imageView.image = port_open? ? App.offline : App.disabled if @pref
      @online = false
      @hide_reconnect = hide_updates
      @reconnect = false

      @task = nil
      @fh = nil
      @error_handle = nil
      ApplicationController.singleton.setConnectorState unless hide_updates
      Logger.debug 'done disconnecting'
    end

    def set_row_state
      if @row
        @row.setOffline unless running? || @awaiting_reconnect
        if port_open?
          @row.setActive if @row
        else
          @row.setInactive if @row
        end
      end
    end

    def destroyRecordAndSelect(id=nil, sender=nil)
        disconnect if running?

        Dispatch::Queue.main.async do
          destroy_model
          if id && ConnectorsViewController.sharedController.connectors_list
            ConnectorsViewController.sharedController.connectors_list.selectRowIndexes NSIndexSet.indexSetWithIndex(id), byExtendingSelection:true
            if sender
              ConnectorsViewController.sharedController.tableViewSelectionDidChange(sender)
            end
          end
        end
        @disconnect_port_queue ||= Dispatch::Queue.new("#{App.queue_prefix}.disconnect.#{@reference}")
        @disconnect_port_queue.async do
            data = {
                'publish' => 'false'
            }
            res = App.api_delete("/connectors/#{@connector_id}", data)
            if !res
              Logger.debug "error deleting connector: #{res.inspect}"
            end
        end
    end

    def destroy
      destroyRecordAndSelect nil
    end

    def remove_row
      if @row
        Logger.debug @row.inspect
        #ApplicationController.singleton.panel.removeRowView @row
        @row.remove
        @row = nil
      end
    end

    def destroy_model
        ApplicationController.singleton.managedObjectContext.deleteObject self.model
        App.save!
        remove_row
        App.global.connectors.delete(self)
        ConnectorsViewController.sharedController.connectors_list.reloadData if ConnectorsViewController.sharedController.connectors_list
        ApplicationController.singleton.setConnectorState
    end

    def getAuthUsers
        @get_auth_user_queue ||= Dispatch::Queue.new("get_user_queue:#{@connector_id}")
        @get_auth_user_queue.async do
            Logger.debug 'getting data'
            res = App.api_get("/connectors/#{@connector_id}/auths")
            @auth_users = res ? res : []

        end
    end

    def setAuthUsers
      Logger.debug 'setting auth users'
      @set_auth_user_queue ||= Dispatch::Queue.new("set_user_queue:#{@connector_id}")
      @set_auth_user_queue.async do
        e = Pointer.new(:object)
        data = {
            'access_token' => App.global.token,
            'auths' => NSJSONSerialization.dataWithJSONObject( { 'auths' => @auth_users }, options:0, error:e),
            'publish' => 'false'
        }
        res = App.api_put("/connectors/#{@connector_id}/auths", data)
        Logger.debug res.inspect
      end
    end

    def addAuthUser(username, password)
        @add_auth_user_queue ||= Dispatch::Queue.new("add_user_queue:#{@connector_id}")
        @add_auth_user_queue.async do
            data = {
                'username' => username,
                'password' => password,
                'publish' => 'false'
            }
            res = App.api_post("/connectors/#{@connector_id}/auths",data)
            if res
                @auth_users << { :username => username, :password => password }
            end
        end
    end

    def deleteAuthUser(username)
        @del_auth_user_queue ||= Dispatch::Queue.new("del_user_queue:#{@connector_id}")
        @del_auth_user_queue.async do
            data = {
                'publish' => 'false'
            }
            res = App.api_delete("/connectors/#{@connector_id}/auths/#{username}",data)
            if res
                @auth_users.delete_if { |v| v[:username] == username }
            end
        end
    end
end
