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

    attr_accessor :model
    attr_accessor :entity
    attr_accessor :auth_users
    attr_accessor :thread

    def initialize(data)
        @host = data.host
        @port = data.port

        set_connection_string
        @connector_id = data.connector_id
        @subdomain = data.subdomain
        @cname = data.cname
        @start_on_boot = data.start_on_boot == 1
        @_init = @start_on_boot
        @auth_type = data.auth_type
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

        #@main_queue = "#{App.queue_prefix}.connector.#{@connector_id}"

        current_index = App.global.index + App.global.connectors.size

        ApplicationController.singleton.status_menu.insertItem menu_item, atIndex: current_index
        App.global.connectors << self
        ApplicationController.singleton.handleMenuDivider

        @published_state = nil
        publish_state

        start_thread
        self
    end

    def online?
        @online
    end

    def start_thread
        begin
        #    @thread = Thread.new do
                self.performSelectorInBackground('monitor_port:', withObject: @retry_seconds)
        #    end
        rescue
            Logger.debug "RESCUE FROM THREAD FAILURE"
            #@thread = nil
            start_thread
        end
    end

    def publish_state(force = false)
        current_state = port_open?
        if (current_state != @published_state) || force
            ApplicationController.singleton.socket.send("STATE:#{@connector_id}:#{current_state ? 'on' : 'off'}")
            @published_state = current_state
        end
    end

    def set_port_online
        connect if @_init
        @timeout += @retry_seconds if online?
        Logger.debug "timeout: #{@timeout}"
        reconnect if running? && @timeout > @retry_seconds * 2
        return if @current_port_status == true
        @current_port_status = true
            # port is online
        #if port_open
                #App.global.ssh["#{@port.to_s}#{@host}"].monitorSession if running?
        #Dispatch::Queue.main.async {
                    publish_state
                    Logger.debug "port is running: #{@port}"
                    @menu_item.image = running? ? App.online : App.offline
                    @menu_item.setEnabled true
                    @pref.imageView.image = (running? ? App.online : App.offline) if @pref

                    ### Logger.debug "TIMEOUT AT: #{@timeout} (#{@host}:#{@port})"

        #}

    end
    def set_port_offline

        return if @current_port_status == false
        @current_port_status = false
        #Dispatch::Queue.main.async {
                    publish_state
                    @menu_item.image = App.disabled
                    @pref.imageView.image = App.disabled if @pref
                    if running? || @hide_reconnect
                        Logger.debug 'Port is closed but it is still running.'
                        disconnect(true)
                        queue_reconnect
                    elsif !@awaiting_reconnect
                        @menu_item.setEnabled false
                    end
        #}

        #end
    end

    def connection_string=(connection_string)
        data = ConnectorMonitor.parse_connection_string(connection_string)
        @host = data[:host]
        @port = data[:port]
    end

    def self.parse_connection_string(connection_string)
        data = {}
        if connection_string =~ /^[0-9]*$/
            Logger.debug 'only port'
            data[:host] = 'localhost'
            data[:port] = connection_string.to_i
        elsif connection_string =~ /\:/
            Logger.debug 'both'
            data[:host], data[:port] = connection_string.split(':')
            data[:port] = data[:port].to_i
        else
            Logger.debug 'only host'
            data[:host] = connection_string
            data[:port] = 80
        end
        data
    end

    # TODO: on creation, it autoboots but acts a bit funky and keeps disconnecting
    def self.create(opts={})

        data = self.parse_connection_string(opts[:connection_string]).merge({
            'subdomain' => opts[:subdomain],
            'cname' => opts[:cname],
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
            ConnectorMonitor.create_model(opts)
        end
    end

    def self.create_model(data)
        puts 'model:'
        puts data.inspect
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
        if online? && ((@model.host != @host) || @model.port != @port)
            @reconnect_after_save = true
            set_port_offline
            event_disconnect(true)
        end
        save_model
        @save_connector_queue ||= Dispatch::Queue.new("save_connector:#{@connector_id}")
        set_connection_string
        set_menu_item_title
        set_pref_title
        @menu_item.image = port_open? ? (online? ? App.online : App.offline) : App.disabled
        ConnectorsViewController.sharedController.connectors_list.reloadData() if ConnectorsViewController.sharedController.connectors_list
        @save_connector_queue.async do
            data = {
                'host' => @model.host,
                'port' => @model.port,
                'subdomain' => @model.subdomain,
                'cname' => @model.cname,
                'auth_type' => @model.auth_type,
                'computer_name' => NSHost.currentHost.localizedName,
                'publish' => 'false'
            }
            App.api_put("/connectors/#{@connector_id}", data)
            if @reconnect_after_save && port_open?
                event_connect(@event_connection_string, @event_tunnel_string)
            end
            @reconnect_after_save = false
        end
    end

    def save_model
        @model.start_on_boot = @start_on_boot
        @model.host = @host
        @model.port = @port
        @model.auth_type = @auth_type
        @model.cname = @cname
        @model.connector_id = @connector_id
        @model.subdomain = @subdomain
        ApplicationController.singleton.save
    end

    def self.all
        connectors = Entity.findFromContext(ApplicationController.singleton.managedObjectContext, withEntity:'Connector', andPredicate:nil, options:{})
        #Logger.debug connectors.count
        connectors
    end

    def self.load_all
        if App.global.connectors.size == 0
            self.all.each do |connector|
                ConnectorMonitor.new(connector)
            end
        end
        # now that they're all loaded, let's download the list and synchronize. we may have to destroy old connectors
        @load_sync ||= Dispatch::Queue.new("load_sync:connectors")
        @load_sync.async do
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
                #deleted_connector.destroy_model
            end
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
        reconnect = false
        if online? && (data.has_key?('host') || data.has_key?('port'))
            reconnect = true
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
        if reconnect
            event_connect(@event_connection_string, @event_tunnel_string)
        end
    end

    def menu_item
      return @menu_item if @menu_item
      @menu_item = NSMenuItem.new
      @menu_item.image = App.offline
      set_menu_item_title
      @menu_item.action = 'toggleState:'
      @menu_item.target = self
      @menu_item
    end

    def set_connection_string
        @connection_string = "#{@host}:#{@port}"
    end

    def set_menu_item_title
      @menu_item.title = "#{@connection_string} → " + (@cname.to_s == '' ? "#{@subdomain}.#{App.global.suffix}" : @cname)
    end

    def pref tableView
        #return @pref if @pref
        @pref = tableView.makeViewWithIdentifier "ConnectorPref", owner:self
        set_pref_title
        @pref.imageView.image = port_open? ? (running? ? App.online : App.offline) : App.disabled
        @pref
    end
    def set_pref_title
        @pref.textField.stringValue = @connection_string if @pref
    end

    def toggleState(menu_item)
        Logger.debug 'Toggling state.'
        menu_item.state == NSOnState ? disconnect : connect
    end

    def connect
      Logger.debug 'Boot.'
      @_init = false
      return if running?
      @hide_reconnect = false
      @awaiting_reconnect = false
      @reconnect = true
      @timeout = 0
      @connector_queue ||= Dispatch::Queue.new("#{App.queue_prefix}.ssh_start.#{@reference}")
      @connector_queue.async do
        Logger.debug 'Sending connection data.'
        data = {
          'connector_id' => self.model.valueForKey('connector_id'),
          'publish' => 'false'
        }
        response = App.api_post("/tunnels",data)
        Logger.debug response.inspect
        if response
          @response = response
          event_connect @response['connection_string'], @response['tunnel_string']
        else
          # publish_disconnect
          @awaiting_reconnect = true
          queue_reconnect
        end
      end
    end

    def event_connect(connection_string, tunnel_string)
        return disconnect if connection_string.to_s == '' || tunnel_string.to_s == ''
        Dispatch::Queue.main.async do
            Logger.debug "STARTING TUNNEL!"
            @menu_item.state = NSOnState
            @event_connection_string = connection_string
            @event_tunnel_string = tunnel_string
            # create a new task
            Logger.debug "REFERENCE: #{@reference}"
        #@connector_queue ||= Dispatch::Queue.new("#{App.queue_prefix}.ssh_start.#{@reference}")
        #@connector_queue.async do
            @task = NSTask.new
            env = NSProcessInfo.processInfo.environment
            ##CFMakeCollectable(@task)
            @task.setEnvironment({"CID" => @connector_id,"TOKEN" => App.global.token, 'SSH_SOCK_AUTH' => env.objectForKey("SSH_AUTH_SOCK")})
            @task.setLaunchPath("/usr/bin/ssh")
            Logger.debug "\"#{tunnel_string}\" \"#{connection_string}\" #{@connector_id}"
            Logger.debug "Private Key Path: #{App.private_key_path}"
            Logger.debug "Public Key Path: #{App.public_key_path}"
            arr = ["-2", connection_string, "-o UserKnownHostsFile=\"#{App.public_key_path.gsub('"', '\"')}\"", "-o SendEnv=CID", "-o SendEnv=TOKEN", "-R #{tunnel_string}:#{@host}:#{@port}", "-i", App.private_key_path]
            @task.setArguments(arr)

            Logger.debug "EVENT CONNECT"
            po = NSPipe.new
            ##CFMakeCollectable(po)
            p_error = NSPipe.new
            ##CFMakeCollectable(p_error)
            @task.standardOutput = po
            @task.standardError = p_error
            @task.launch

            @error_handle = p_error.fileHandleForReading
            ##CFMakeCollectable(@error_handle)
            @fh = po.fileHandleForReading
            ##CFMakeCollectable(@fh)

            @error_handle.waitForDataInBackgroundAndNotifyForModes [NSEventTrackingRunLoopMode, NSDefaultRunLoopMode]
            @fh.waitForDataInBackgroundAndNotifyForModes [NSEventTrackingRunLoopMode, NSDefaultRunLoopMode]

            # error handling
            #Logger.debug 'Adding error handling.'
            #Dispatch::Queue.main.async do
                NSNotificationCenter.defaultCenter.addObserver(self, selector:'receivedError:', name:NSFileHandleDataAvailableNotification, object: @error_handle)

                # regular handling
                NSNotificationCenter.defaultCenter.addObserver(self, selector:'receivedPing:', name:    NSFileHandleDataAvailableNotification, object: @fh)
                NSNotificationCenter.defaultCenter.addObserver(self, selector:'taskTerminated:', name: NSTaskDidTerminateNotification, object: @task)
            #end
            Logger.debug 'Connecting to port.'
            @online = true
            @menu_item.image = App.online
            @pref.imageView.image = App.online if @pref
            ApplicationController.singleton.setConnectorState
        #end
        end
    end

    def monitor_port(seconds=0)
        seconds = seconds.to_f
        loop do
            catch(:done) do
                Logger.debug "monitoring port status of #{@port}"
                if connect_to(@host, @port, 1)
                    Logger.debug 'set online'
                    set_port_online
                else
                    Logger.debug 'set offline'
                    set_port_offline
                end
                Logger.debug "----"
                100.times do
                    if @check_port_status
                        @check_port_status = false
                        throw :done
                    else
                        sleep seconds / 100.0
                    end
                end
            end
        end
    end

    def connect_to(host, port, timeout)
      begin
        Logger.debug "trying to connect locally to #{host}:#{port}"
        return Sock.connect(host, port:port)
      rescue Exception => e
        Logger.debug e.inspect
        false
      end
    end

    def port_open?
        #connect_to(@host, @port, 1)
        @check_port_status = true
        @current_port_status
    end

    def reconnect
        disconnect
        connect
    end

    def running?
        @online
    end

    def queue_reconnect(seconds=nil)
      self.performSelectorInBackground('queue_reconnect_in_background:', withObject:seconds)
    end

    def queue_reconnect_in_background(seconds=nil)
      seconds ||= @retry_seconds
      Logger.debug "Retrying in #{seconds} seconds."
      sleep seconds
      if port_open? && @awaiting_reconnect && !online? && ApplicationController.singleton.socket.online?
        Logger.debug "Port is open again."
        connect
      elsif @awaiting_reconnect && !online?
        Logger.debug "Requeueing connection."
        queue_reconnect_in_background seconds
      end
    end

    def receivedError(notif)
        fh = notif.object
        data = fh.availableData.to_s
        Logger.debug data
        return unless running?

        data = data.lines.first
        if data && data.match(/closed|Killed by signal/)
            Logger.debug "Reconnecting."
        elsif data && data.match(/failed/) && !port_open?
            Logger.debug "Port isn't open."
            disconnect(true)
            queue_reconnect
        elsif data && data.match(/No route to host/i)
            Logger.debug "No internet."
            disconnect(true)
            queue_reconnect
        else
            Logger.debug "Going to reconnect anyway."
            #disconnect
        end
    end

    def receivedPing(notif)
        fh = notif.object
        data = fh.availableData.to_s
        @timeout=0
        Logger.debug data
        fh.waitForDataInBackgroundAndNotifyForModes([NSEventTrackingRunLoopMode, NSDefaultRunLoopMode]) if running?
    end

    def taskTerminated(notif)
       Logger.debug "Task was terminated."
       disconnect(true)
       queue_reconnect
    end

    def disconnect(awaiting_reconnect=false)
      if @awaiting_reconnect && (awaiting_reconnect == false)
        @awaiting_reconnect = false
        event_disconnect(false)
      else
        @awaiting_reconnect = awaiting_reconnect
        publish_disconnect
        event_disconnect(false)
      end
    end

    def publish_disconnect
      @disconnect_port_queue ||= Dispatch::Queue.new("#{App.queue_prefix}.disconnect.#{@reference}")
      @disconnect_port_queue.async do
        data = {
          'publish' => 'false'
        }
        Logger.debug 'publishing disconnect'
        res = App.api_delete("/tunnels/#{@connector_id}", data)
      end
    end

    def force_disconnect
      @awaiting_reconnect = false
      event_disconnect
    end

    def event_disconnect(hide_updates = false)

        Logger.debug 'Disconnecting task.'
        unless @awaiting_reconnect
            @menu_item.state = NSOffState
            @menu_item.setEnabled(false) unless port_open?
        end

        NSNotificationCenter.defaultCenter.removeObserver(self, name:NSFileHandleDataAvailableNotification, object: @error_handle)
        NSNotificationCenter.defaultCenter.removeObserver(self, name:NSFileHandleDataAvailableNotification, object: @fh)
        NSNotificationCenter.defaultCenter.removeObserver(self, name:NSTaskDidTerminateNotification, object: @task)

        @task.terminate if running?
        @pref.imageView.image = port_open? ? App.offline : App.disabled if @pref
        @menu_item.image = port_open? ? App.offline : App.disabled
        @online = false
        @hide_reconnect = hide_updates
        @reconnect = false

        @task = nil
        @fh = nil
        @error_handle = nil
        ApplicationController.singleton.setConnectorState unless hide_updates
        Logger.debug 'done disconnecting'
    end

    def destroy
        disconnect if running?

        @disconnect_port_queue ||= Dispatch::Queue.new("#{App.queue_prefix}.disconnect.#{@reference}")
        @disconnect_port_queue.async do
            data = {
                'publish' => 'false'
            }
            res = App.api_delete("/connectors/#{@connector_id}", data)
            if res
              Logger.debug "deleting model too"
              self.destroy_model
            else
              Logger.debug "error deleting connector: #{res.inspect}"
            end
        end
    end
    def destroy_model
        ApplicationController.singleton.managedObjectContext.deleteObject self.model
        App.save!
        #@port_monitor.connector = nil
        ApplicationController.singleton.status_menu.removeItem(@menu_item) if @menu_item # && @menu_item.menu
        App.global.connectors = App.global.connectors.keep_if { |c| c != self }
        ApplicationController.singleton.handleMenuDivider
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
