# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/osx'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'Portly'
  app.version = '15'
  app.short_version = '0.3.8'
  app.deployment_target = '10.7'
  app.codesign_certificate = "Developer ID Application: Fully Brand LLC (DENUL24P9C)"
  app.icon = 'icon.icns'
  app.entitlements['com.apple.security.app-sandbox'] = false

  app.frameworks += ['IOKit', 'CoreFoundation', 'Cocoa', 'Security']
  app.embedded_frameworks = ['vendor/Sparkle.framework']
  app.vendor_project('vendor/SocketStream', :static)
  app.vendor_project('vendor/Sock', :static)
  app.vendor_project('vendor/Computer', :static)
  app.vendor_project('vendor/HoverButton', :static)
  app.vendor_project('vendor/LoginView', :static)
  app.vendor_project('vendor/LoginWindow', :static)
  app.vendor_project('vendor/LaunchAtLoginController', :static)
  app.vendor_project('vendor/Token', :static)
  app.vendor_project('vendor/Connector', :static)
  app.vendor_project('vendor/UUID', :static)

  app.files_dependencies 'app/inheritable_attrs.rb' => 'app/core_data.rb'
  app.files_dependencies 'app/Entity.rb' => 'app/inheritable_attrs.rb'
  app.files_dependencies 'app/ApplicationController.rb' => 'app/stream.rb'
  app.files_dependencies 'app/ApplicationController.rb' => 'app/ConnectorsViewController.rb'
  app.info_plist['SUFeedURL'] = 'https://getportly.com/downloads/sparkle_updates.xml'
  app.info_plist['SUPublicDSAKeyFile'] = 'dsa_pub.pem'
  app.info_plist['LSUIElement'] = true
  app.info_plist['CFBundleIdentifier'] = 'com.fully.portly'
  app.info_plist['LSApplicationCategoryType'] = 'public.app-category.developer-tools'

end
