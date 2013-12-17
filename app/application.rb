#
#  application.rb
#  port
#
#  Created by Kelly Martin on 3/10/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#


#  Constants

ENVIRONMENT = 'production'
DEBUG = RUBYMOTION_ENV == "development"

PrefsToolbarItemConnectors = "prefsToolbarItemConnectors"
PrefsToolbarItemAccount = "prefsToolbarItemAccount"
PrefsToolbarItemGeneral = "prefsToolbarItemGeneral"

ShowUnreadCount = "ShowUnreadCount"
OpenWithChrome = "OpenWithChrome"
PreferencesSelection = "PreferencesSelection"
Accounts = "Accounts"

KeychainService = "Portly"

class App

    @@singleton = nil
    attr_accessor :connectors
    attr_accessor :index
    attr_accessor :path
    attr_accessor :ssh
    attr_accessor :uuid
    attr_accessor :plan_type

    def self.save!
        error = Pointer.new_with_type('@')
        while(@saving == true) do; end
        @saving = true
        unless ApplicationController.singleton.managedObjectContext.save(error)
            NSApplication.sharedApplication.presentError(error[0])
        end
        @saving = false
    end

    def env
        ENVIRONMENT
    end

    def self.debug?
        DEBUG || false
    end

    def self.version
      NSBundle.mainBundle.infoDictionary.objectForKey("CFBundleShortVersionString")
    end

    def self.development?
        @development ||= ENVIRONMENT == 'development'
    end

    def self.socket
        if App.development?
            {:host => 'localhost', :port => 8900}
        else
            {:host => 'app.getportly.com', :port => 443 }
        end
    end

    def self.free?
      !self.global.plan_type || self.global.plan_type.downcase == 'free'
    end

    def self.api_endpoint
        if App.development?
            'http://localhost:9393/api'
        else
            'https://getportly.com:443/api'
        end
    end

    def self.queue_prefix
        'com.portly.queue'
    end

    def self.link_color
      @link_color ||= NSColor.colorWithCalibratedRed 104.0/255.0, green: 84.0/255.0, blue:90.0/255.0, alpha:1.0
    end

    def self.error=(error)
      @error = error
    end

    def self.error
      @error
    end

    def self.client_id
        return @client_id if @client_id
        p1 = 'c02'
        p2 = '09d'
        p3 = '3ea'
        p4 = 'fec'
        p5 = 'd05'
        p6 = 'f2f'
        p7 = '8f7'
        @client_id = [p1,p2,p3,p4,p5,p6,p7].join('')
    end

    def self.client_secret
        return @client_secret if @client_secret
        p1 = '26a'
        p2 = '1f6'
        p3 = '43c'
        p4 = '98a'
        p5 = 'a11'
        p6 = 'c44'
        p7 = '539'
        p8 = 'ebc'
        p9 = 'ab6'
        p10= '7ee'
        p11= '6ae'
        p12= '211'
        p13= '834'
        p14= 'c77'
        p15= '6d4'
        p16= '31f'
        p17= '669'
        p18= '931'
        p19= 'fa1'
        p20= 'e02'
        p21= '379a5'
        @client_secret = [p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21].join('')
    end

    def self.limit
        2
    end

    def self.forgot_password_url
        "http://getportly.com/reset-password/"
    end

    def self.install_wordpress_plugin_url
      "http://getportly.com/wordpress-support/"
    end

    def self.upgrade_url
      "https://getportly.com/upgrade"
    end

    def self.online
        @online ||= NSImage.imageNamed('online')
    end

    def self.offline
        @offline ||= NSImage.imageNamed('offline')
    end

    def self.disabled
        @disabled ||= NSImage.imageNamed('disabled')
    end

    def self.global
        @@singleton || self.new
    end

    def self.title
        "Portly"
    end

    def self.data_file
        'config.portly'
    end

    def self.private_key_path
        @private_key_path ||= File.join(App.global.path, App.title.downcase, 'portly.key')
    end
    def private_key_path
        @private_key_path ||= File.join(App.global.path, App.title.downcase, 'portly.key')
    end

    def self.public_key_path
        @public_key_path ||= File.join(App.global.path, App.title.downcase, 'portly.host')
    end
    def public_key_path
        @public_key_path ||= File.join(App.global.path, App.title.downcase, 'portly.host')
    end

    def initialize
        @@singleton = self
        self.index = 2
        self.connectors = []
        self.ssh = {}
    end

    def token=(t)
        @token = t
    end

    def token
        @token ? @token.key : ''
    end

    def token_model
        @token
    end

    def self.savePrivateKeyToFile(private_key)
        File.open(App.private_key_path, 'w') do |f|
            f << private_key
            f.chmod(0600)
        end
    end

    def self.savePublicKeyToFile(public_key)
      File.open(App.public_key_path, 'w') do |f|
        f << public_key
        f.chmod(0600)
      end
    end

    def self.get_keys!
      res = App.api_get('/authorizations/keys')
      if res
        App.savePrivateKeyToFile(res['private_key'])
        App.savePublicKeyToFile(res['public_key'])
      end
    end

    def self.stay_awake?
      Logger.debug "State of Stay Awake: #{NSUserDefaults.standardUserDefaults.boolForKey('stay_awake')}"
      NSUserDefaults.standardUserDefaults.boolForKey('stay_awake')
    end

    def suffix
        @token.suffix
    end

    def self.reset_error!
      @error = nil
    end

    def self.api_get(url, data = {})
      self.reset_error!
        data['access_token'] = App.global.token if App.global.token && App.global.token != ''
        getBodyString = []
        data.each { |k,v| getBodyString << "#{k.to_s}=#{v}" }
        getBodyString = getBodyString.join '&'
        getBodyString = "?#{getBodyString}" unless getBodyString == ''
        request = NSMutableURLRequest.alloc.initWithURL NSURL.alloc.initWithString("#{App.api_endpoint}#{url}#{getBodyString}")
        Logger.debug '----'
        Logger.debug "#{App.api_endpoint}#{url}"
        Logger.debug getBodyString
        Logger.debug '----'
        request.setHTTPMethod "GET"
        request.setValue "application/json", forHTTPHeaderField: "content-type"
        resp = Pointer.new_with_type('@')
        err = Pointer.new_with_type('@')
        conn = NSURLConnection.sendSynchronousRequest request, returningResponse: resp, error: err
        if err.value
            err = err.value.code
            if err == -1012
                nil #TODO: handle this 401 later
            else
                nil
            end
        elsif resp.value.statusCode >= 400
          e = Pointer.new(:object)
          c = NSJSONSerialization.JSONObjectWithData(conn, options:0, error: e) rescue {}
          self.error = c['error']
        else
            #conn = NSString.alloc.initWithData(conn, encoding: NSUTF8StringEncoding)
            #puts conn
            #c = JSON.parse(conn)
            e = Pointer.new(:object)
            c = NSJSONSerialization.JSONObjectWithData(conn, options:0, error: e) rescue {}
            return c
        end
    end
    def self.api_delete(url, data)
        self.api_post(url, data, 'DELETE')
    end
    def self.api_put(url, data)
        self.api_post(url, data, 'PUT')
    end


    def self.api_post(url, data, method='POST')
      self.reset_error!
      #@uri ||= URI.parse("#{App.api_endpoint}")
      data['access_token'] = App.global.token if App.global.token && App.global.token != ''
      postBodyString = []
      data.each do |k,v|
        v = v.to_s
        postBodyString << "#{k.to_s}=#{v.gsub('+','%2B').gsub('/','%2F')}"
      end
      postBodyString = postBodyString.join '&'
      postBodyData = postBodyString.dataUsingEncoding(NSUTF8StringEncoding)
      #NSData.dataWithBytes(postBodyString.pointer, length:postBodyString.length)
      request = NSMutableURLRequest.alloc.initWithURL NSURL.alloc.initWithString("#{App.api_endpoint}#{url}")
      Logger.debug '----'
      Logger.debug "#{App.api_endpoint}#{url}"
      Logger.debug postBodyString
      Logger.debug '----'
      request.setHTTPMethod method
      request.setValue "application/x-www-form-urlencoded", forHTTPHeaderField: "content-type"
      request.setHTTPBody postBodyData
      resp = Pointer.new(:object)
      err = Pointer.new(:object)
      conn = NSURLConnection.sendSynchronousRequest request, returningResponse: resp, error: err
      if err.value
          err = err.value.code
          Logger.debug "Error with connection: #{err} for #{method} #{url}"
          if err == -1012
              nil #TODO: handle this 401 later
          else
              nil
          end
      elsif resp.value && resp.value.statusCode >= 400
        conn_string = NSString.alloc.initWithData(conn, encoding: NSUTF8StringEncoding)
        if conn_string.length > 2
          e = Pointer.new(:object)
          result = NSJSONSerialization.JSONObjectWithData(conn, options:0, error: e) rescue {}
          if result.is_a?(Hash)
            self.error = result['error']
          else
            self.error = resp.value.statusCode
          end
        end
        nil
      else
          conn_string = NSString.alloc.initWithData(conn, encoding: NSUTF8StringEncoding)
          if conn_string.length > 2
            e = Pointer.new(:object)
            NSJSONSerialization.JSONObjectWithData(conn, options:0, error: e) rescue {}
          else
            {}
          end
      end
    end

end
