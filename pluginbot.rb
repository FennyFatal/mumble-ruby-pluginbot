#!/usr/bin/env ruby

require './plugin'
Dir["./plugins/*.rb"].each { |f| require f }

require 'mumble-ruby'
require 'rubygems'
require 'ruby-mpd'
require 'thread'
require 'optparse'
require 'i18n'


# copy@paste from https://gist.github.com/erskingardner/1124645#file-string_ext-rb
class String
  def to_bool
    return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class MumbleMPD
  attr_reader :run

  def initialize
    # load all plugins
    require './plugin'
    Dir["./plugins/*.rb"].each do |f| 
      require f 
      puts "Plugin #{f} loaded."
    end
    @plugin = Array.new
    @settings = Hash.new()
    #Initialize default values

    #Read config file if available 
    begin
      require_relative 'pluginbot_conf.rb'
      std_config()
    rescue
      puts "Config could not be loaded! Using default configuration."
    end

    #Try to reinit extra config (only on success on restarts)
    begin
      ext_config()
      puts "restarting bot"
    rescue
    end

    OptionParser.new do |opts|
      opts.banner = "Usage: pluginbot.rb [options]"

      opts.on("--config=", "(Relative) path and filename to config") do |v|
      puts "parse extra config"
        if File.exist? v
          begin
            require_relative v
            ext_config()
          rescue
            puts "Your config could not be loaded!"
          end
        else
          puts "Config path- and/or filename is wrong!"
          puts "used #{v}"
          puts "Config not loaded!"
        end
      end

      opts.on("--mumblehost=", "IP or Hostname of mumbleserver") do |v|
        @settings[:mumbleserver_host] = v
      end

      opts.on("--mumbleport=", "Port of Mumbleserver") do |v|
        @settings[:mumbleserver_port] = v
      end

      opts.on("--name=", "The Bot's Nickname") do |v|
        @settings[:mumbleserver_username] = v
      end

      opts.on("--userpass=", "Password if required for user") do |v|
        @settings[:mumbleserver_userpassword] = v
      end

      opts.on("--targetchannel=", "Channel to be joined after connect") do |v|
        @settings[:mumbleserver_targetchannel] = v
      end

      opts.on("--bitrate=", "Desired audio bitrate") do |v|
        @settings[:quality_bitrate] = v.to_i
      end

      opts.on("--fifo=", "Path to fifo") do |v|
        @settings[:mpd_fifopath] = v.to_s
      end

      opts.on("--mpdhost=", "MPD's Hostname") do |v|
        @settings[:mpd_host] = v
      end

      opts.on("--mpdport=", "MPD's Port") do |v|
        @settings[:mpd_port] = v.to_i
      end

      opts.on("--controllable=", "true if bot should be controlled from chatcommands") do |v|
        @settings[:controllable] = v.to_bool
      end

      opts.on("--certdir=", "path to cert") do |v|
        @settings[:certdirectory] = v
      end
    end.parse! 
    @settings[:ducking_volume] = 20 if @settings[:ducking_volume].nil?
    @configured_settings = @settings.clone 
    
    # set up language
    I18n.load_path = Dir["languages/*.yml"]
    @configured_settings[:language] ||= :en
    I18n.default_locale=@configured_settings[:language]
  end

  def init_settings
    @run = false
    @cli = nil
    @cli = Mumble::Client.new(@settings[:mumbleserver_host], @settings[:mumbleserver_port]) do |conf|
      conf.username = @settings[:mumbleserver_username]
      conf.password = @settings[:mumbleserver_userpassword]
      conf.bitrate = @settings[:quality_bitrate].to_i
      conf.vbr_rate = @settings[:use_vbr]
      conf.ssl_cert_opts[:cert_dir] = File.expand_path(@settings[:certdirectory])
    end
  end

  def disconnect
    @cli.disconnect if @cli.connected?
  end

  def calc_overall_bandwidth(framelength, bitrate)
    ( 1000 / framelength.to_f * 320 ).to_i + bitrate
  end

  def get_overall_bandwidth
    #( 1000/ @cli.get_frame_length.to_f * 320 ).to_i + @cli.get_bitrate
    calc_overall_bandwidth(@cli.get_frame_length, @cli.get_bitrate)
  end

  def mumble_start

    @cli.on_server_config do |serverconfig|
      @settings[:mumbleserver_imagelength] = serverconfig.image_message_length
      @settings[:mumbleserver_messagelength] = serverconfig.message_length
      @settings[:mumbleserver_allow_html] = serverconfig.allow_html
    end

    @cli.on_suggest_config do |suggestconfig|
      @settings[:mumbleserver_version] = suggestconfig.version
      @settings[:mumbleserver_positional] = suggestconfig.positional
      @settings[:mumbleserver_push_to_talk] = suggestconfig.push_to_talk
    end

    @cli.connect
    max_connecting_time = 10 
    while not @cli.connected? do
      sleep(0.5)
      puts "Connecting to the server is still ongoing." if @settings[:debug]
      max_connecting_time -= 1
      if max_connecting_time < 1
        puts "Connection timed out" if @settings[:debug]
        @cli.disconnect
        break
      end
    end
    if @cli.connected?
      puts "connected"
      begin
        @cli.join_channel(@settings[:mumbleserver_targetchannel])
      rescue
        puts "[joincannel]#{$1} Can't join #{@settings[:mumbleserver_targetchannel]}!" if @settings[:debug]
      end

      begin
        Thread.kill(@duckthread)
      rescue
        puts "[killduckthread] can't kill because #{$!}" if @settings[:debug]
      end

      #Start duckthread
      @duckthread = Thread.new do
        while (true == true)
          while (@cli.player.volume != 100)
            @cli.player.volume += 2 if @cli.player.volume < 100
            sleep 0.02
          end
          Thread.stop
        end
      end

      begin
        @cli.set_comment("")
        @settings[:set_comment_available] = true
      rescue NoMethodError
        puts "[displaycomment]#{$!}" if @settings[:debug]
        @settings[:set_comment_available] = false 
      end

      @cli.on_user_state do |msg|
        handle_user_state_changes(msg)
      end

      @cli.on_text_message do |msg|
        handle_text_message(msg)
      end

      @cli.on_udp_tunnel do |udp|
        if @settings[:ducking] == true
          @cli.player.volume = ( @settings[:ducking_volume] |  0x1 ) - 1
          @duckthread.run if @duckthread.stop?
        end
      end

      @run = true
      @cli.player.stream_named_pipe(@settings[:mpd_fifopath]) 

      #init all plugins
      init = @settings.clone
      init[:cli] = @cli

      puts "initplugins"
      Plugin.plugins.each do |plugin_class|
        @plugin << plugin_class.new
      end

      maxcount = @plugin.length 
      allok = 0
      while allok != @plugin.length do
        allok = 0
        @plugin.each do |plugin|
          init = plugin.init(init)
          if plugin.name != "false"
            allok += 1
          end
        end
        maxcount -= 1
        break if maxcount <= 0 
      end
      puts "maybe not all plugin functional!" if maxcount <= 0

      ## Enable Ticktimer Thread
      @ticktimer = Thread.new do
        timertick
      end

    end
  end

  private 

  def timertick
    ticktime = ( @settings[:ticks_per_hour] || 3600 )
    while (true==true)
      sleep(3600/ticktime)
      time = Time.now
      @plugin.each do |plugin|
        plugin.ticks(time)
      end
    end
  end

  def handle_user_state_changes(msg)
    #msg.actor = session_id of user who did something on someone, if self done, both is the same.
    #msg.session = session_id of the target
  end

  def handle_text_message(msg)
    if !msg.actor.nil?
      # else ignore text messages from the server
      # This is hacky because mumble uses -1 for user_id of unregistered users,
      # while mumble-ruby seems to just omit the value for unregistered users.
      # With this hacky thing commands from SuperUser are also being ignored.
      if @cli.users[msg.actor].user_id.nil?
        msg_userid = -1
        sender_is_registered = false
      else
        msg_userid = @cli.users[msg.actor].user_id
        sender_is_registered = true
      end

      # check if User is on a blacklist
      begin
        if @settings.has_key?(@cli.users[msg.actor].hash.to_sym)
          sender_is_registered = false
          puts "user in blacklist!" if @settings[:debug]
          #(if on blacklist virtually unregister her/him)
        end
      rescue
        #catch when user has'nt a hash. (not registerd)
      end

      # generating help message.
      # each command adds his own help
      help ="<br />"    # start with empty help
      # the help command should be the last command in this function
      cc = @settings[:controlstring]

      #FIXME
      #msg.message.gsub!(/(<[^<^>]*>)/, "") #Strip html tags. #BEFORE doing this we need to ensure that no plugin needs the html source code. For example youtube plugin needs them...

      if msg.message == @superpassword+"restart"
        @settings = @configured_settings.clone
        @cli.text_channel(@cli.me.current_channel,@superanswer);
        @run = false
        @cli.disconnect
      end

      if msg.message == @superpassword+"reset"
        @settings = @configured_settings.clone
        @cli.text_channel(@cli.me.current_channel,@superanswer);
      end

      if (sender_is_registered == true) || (@settings[:listen_to_registered_users_only] == false)
        #Check whether message is a private one or was sent to the channel.
        # Private message looks like this:   <Hashie::Mash actor=54 message="#help" session=[119]>
        # Channel message:                   <Hashie::Mash actor=54 channel_id=[530] message="#help">
        # Channel messages don't have a session, so skip them
        if ( msg.session ) || ( @settings[:listen_to_private_message_only] != true )
          if @settings[:controllable] == true 
            if msg.message.start_with?("#{@settings[:controlstring]}") && msg.message.length >@settings[:controlstring].length #Check whether we have a command after the controlstring.
              message = msg.message.split(@settings[:controlstring])[1 .. -1].join() #Remove @settings[:controlstring]
              @plugin.each do |plugin|
                plugin.handle_chat(msg, message)
              end

              if message == 'about'
                @cli.text_user(msg.actor, I18n.t('about'))
              end

              if message == 'settings' 
                out = "<table>"
                @settings.each do |key, value|
                  out << "<tr><td>#{key}</td><td>#{value}</td></tr>" if key != :logo
                end
                out << "</table>"
                @cli.text_user(msg.actor, out)
              end

              if message.split[0] == 'set' 
                if !@settings[:need_binding] || @settings[:boundto]==msg_userid
                  setting = message.split('=',2)
                  @settings[setting[0].split[1].to_sym] = setting[1] if setting[0].split[1] != nil
                end
              end

              if message == 'bind'
                @settings[:boundto] = msg_userid if @settings[:boundto] == "nobody"
              end

              if message == 'unbind'
                @settings[:boundto] = "nobody" if @settings[:boundto] == msg_userid
              end

              if message == 'reset' 
                @settings = @configured_settings.clone if @settings[:boundto] == msg_userid
              end

              if message == 'restart'
                if @settings[:boundto] == msg_userid
                  @run=false
                  @cli.disconnect
                end
              end

              if message == 'register'
                if @settings[:boundto] == msg_userid
                  @cli.me.register
                end
              end

              if message.split(" ")[0] == 'blacklist'
                if @settings[:boundto] == msg_userid
                  if @cli.find_user(message.split[1..-1].join(" ")) != nil
                    @settings[@cli.find_user(message.split[1..-1].join(" ")).hash.to_sym] = message.split[1..-1].join(" ")
                    @cli.text_user(msg.actor, I18n.t("ban.active"))
                    @cli.text_user(msg.actor, "@settings[#{@cli.find_user(message.split[1..-1].join(" ")).hash.to_sym}] = \"#{message.split[1..-1].join(" ")}\"")
                  else
                    @cli.text_user(msg.actor, I18n.t("user.not.found", :user => message.split[1..-1].join(" ")))
                  end
                end
              end

              if message == 'ducking'
                @settings[:ducking] = !@settings[:ducking]
                if @settings[:ducking] == false 
                  @cli.text_user(msg.actor, I18n.t("ducking._off"))
                else
                  @cli.text_user(msg.actor, I18n.t("ducking._on"))
                end
              end

              if message == 'duckvol'
                @cli.text_user(msg.actor, I18n.t("ducking.volume.settings", :volume_relative => @settings[:ducking_volume]))
                if @settings[:ducking] == false 
                  @cli.text_user(msg.actor, I18n.t("ducking._off"))
                else
                  @cli.text_user(msg.actor, I18n.t("ducking._on"))
                end
              end

              if message.match(/^duckvol [0-9]{1,3}$/)
                volume = message.match(/^duckvol ([0-9]{1,3})$/)[1].to_i 
                if (volume >=0 ) && (volume <= 100)
                  @settings[:ducking_volume] = volume
                  @cli.text_user(msg.actor, I18n.t("ducking.volume.set", :volume => volume))
                else
                  @cli.text_user(msg.actor, I18n.t("ducking.volume.out_of_range"))
                end
              end

              if message == 'bitrate'
                begin
                  @cli.text_user(msg.actor, I18n.t("bitrate.set", :bitrate => @cli.get_bitrate.to_s))
                rescue
                  @cli.text_user(msg.actor, "bitrate.error")
                end
              end

              if message.match(/^bitrate [0-9]{1,3}$/)
                bitrate = message.match(/^bitrate ([0-9]{1,3})$/)[1].to_i * 1000
                begin
                  @cli.set_bitrate(bitrate)
                  @cli.text_user(msg.actor, I18n.t("bitrate.set", :bitrate => @cli.get_bitrate))
                  @cli.text_user(msg.actor, I18n.t("bandwidth.set", :bandwidth => get_overall_bandwidth))
                rescue
                  @cli.text_user(msg.actor, I18n.t("bitrate.error"))
                end
              end

              if message == 'framesize'
                begin
                  @cli.text_user(msg.actor, I18n.t("framesize.set", :framesize => @cli.get_frame_length.to_s))
                rescue
                  @cli.text_user(msg.actor, I18n.t("framesize.error"))
                end
              end

              if message.match(/^framesize [0-9]{1,2}$/)
                framelength = message.match(/^framesize ([0-9]{1,2})$/)[1].to_i
                begin
                  @cli.set_frame_length(framelength)
                  @cli.text_user(msg.actor, I18n.t("framesize.set", :framesize => @cli.get_frame_length.to_s))
                  @cli.text_user(msg.actor, I18n.t("bandwidth.set", :bandwidth => get_overall_bandwidth))
                  @cli.text_user(msg.actor, I18n.t("bandwidth.max", :bandwidth => @cli.max_bandwidth))
                rescue
                  @cli.text_user(msg.actor, I18n.t("bitrate.error"))
                end
              end

              if message == 'bandwidth'
                begin
                   @cli.text_user(msg.actor, I18n.t("bandwidth.settings", :overall => get_overall_bandwidth, :audio => @cli.get_bitrate.to_s , :framesize => @cli.get_frame_length.to_s))
                rescue
                  @cli.text_user(msg.actor, "bitrate.error")
                end
              end

              if message == 'plugins'
                help = I18n.t("plugins.loaded._shead")
                @plugin.each do |plugin|
                  help << plugin.name + "<br />"
                end
                help << I18n.t("plugins.loaded._ehead")

                help << I18n.t("plugins.general_help", :control => @settings[:controlstring])
                @cli.text_user(msg.actor, help)
              end

              # early in development, not documented now until it works :)
              if message == "jobs"
                output = ""
                Thread.list.each do |t|  
                  if t["process"]!=nil
                      output << I18n.t("jobs.status", :process => t["process"], :status => t.status.to_s, :name=> t.user.name)
                  end
                  @cli.text_user(msg.actor, output)  
                end
              end

              if message == 'internals'
                @cli.text_user(msg.actor, I18n.t("help.internal", :cc => @settings[:controlstring]))
              end

              if message.split[0] == 'help'
                if message.split[1]=='all' #Send help texts of all plugins.
                    @plugin.each do |plugin|
                        help = plugin.help(help.to_s)
                        @cli.text_user(msg.actor, help)
                    end
                end
                if message.split[1]!=nil #Send help for a specific plugin.
                  @plugin.each do |plugin|
                    help = plugin.help('') if plugin.name.upcase == message.split[1].upcase
                  end

                  @cli.text_user(msg.actor, help)
                else #Send default help text.
                    @cli.text_user(msg.actor, I18n.t("help.default", :cc=> @settings[:controlstring]))
                end
              end
            end
          end
        else
          puts "Debug: Not listening because @settings[:listen_to_private_message_only] is true and message was sent to channel." if @settings[:debug]
        end
      else
        puts "Debug: Not listening because @settings[:listen_to_registered_users_only] is true and sender is unregistered or on a blacklist." if @settings[:debug]
      end
    end
  end
end

loop do #https://github.com/bbatsov/ruby-style-guide#infinite-loop
  client = MumbleMPD.new
  puts "pluginbot is starting..." 
  client.init_settings
  puts "start"
  client.mumble_start
  sleep 3
  begin
    while client.run == true
        sleep 0.5
    end
  rescue
    puts "An error occurred: #{$!}"
    puts "Backtrace: #{$@}"
    client.disconnect
  end
  puts " "
  puts "----------------------------------------------"
  puts "-- Restart                                  --"
  puts "----------------------------------------------"
  sleep 0.5
end
