def std_config()
	puts "Config loaded!"
    @settings = {   version: 2.0, 
                    main_tempdir: "/home/botmaster/temp/",
                    ducking: false,
                    control_automute: true,
                    chan_notify: 0x0000, 
                    controlstring: ".", 
                    debug: true, 
                    listen_to_private_message_only: false, 
                    listen_to_registered_users_only: true, 
                    use_vbr: 1, 
                    stop_on_unregistered_users: true,
                    use_comment_for_status_display: true,
                    #set_comment_available: false,
                    mumbleserver_host: "127.0.0.1",
                    mumbleserver_port: 64738,
                    mumbleserver_username: "MumbleRubyPluginbot",
                    mumbleserver_userpassword: "",
                    mumbleserver_targetchannel: "Bottest",
                    quality_bitrate: 72000,
                    initial_volume: 65,
                    mpd_fifopath: "/home/botmaster/mpd1/mpd.fifo",
                    mpd_host: "localhost",
                    mpd_port: 7701,
                    controllable: true,
                    certdirectory: "/home/botmaster/src/certs",
                    need_binding: false,
                    boundto: "nobody",
                    logo: "<img src='data:image/png;base64,
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'/>"
                }
	@superanswer = "<img src='data:image/png;base64,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'/>"
  @superpassword = "kaguBe gave me all the power from kaguBe and I wish to "

  ####################################
  # Miscellaneous settings ###########
  #@settings[:controlstring] =                     "."                    #Change it if you want to use another starting string/symbol for the commands.
  #@settings[:debug] =                             true                   #Whether debug mode is on or off.
  #@settings[:use_vbr] =                           1                      #Default for mumble-ruby is 0 in order to use cbr, set to 1 to use vbr.
  #@settings[:listen_to_private_message_only] =    false                  #Whether the bot should only listen to private messages.
  #@settings[:listen_to_registered_users_only] =   true                   #Whether the bot should only react to commands from registered users.
  #@settings[:stop_on_unregistered_users] =        true                   #Whether the bot should stop playing music if a unregistered user joins the channel.
  #@settings[:use_comment_for_status_display] =    true                   #Whether to use comment to display song info; false = send to channel, true = comment.
  #@settings[:ducking_volume] =                    20                     #Percentage of normal volume to ducking down
  #Set default mumble server
  #@settings[:mumbleserver_host] = "127.0.0.1"
  #@settings[:mumbleserver_port] = "64739"
  #Set default user
  #@settings[:mumbleserver_username] ="Musikbot"
  #@settings[:mumbleserver_userpassword] = ""
  #@settings[:mumbleserver_targetchannel] ="Chefetage"
  #Set default streaming settings
  #@settings[:quality_bitrate] = 72000
  #@settings[:mpd_fifopath] = "/home/botmaster/mpd1/mpd.fifo"
  #@settings[:mpd_host] = "localhost"
  #@settings[:mpd_port] = 7701
  #controllable?
  #@settings[:controllable] = true
  #Certification Directory
  #@settings[:certdirectory] = "/home/botmaster/certs/"
  ####################################



  ######################################
  # Settings for plugins start here ####
  ######################################

  ###########################
  # Youtube plugin: #########
  ###########################
  @settings[:youtube_downloadsubdir] = "downloadedfromyt/"
  # This is the RELATIVE path where the plugin stores its permanent files.
  # Note that you also need to set @settings[:mpd_musicfolder] in the next
  # section of the "Mpd plugin", because the complete path is
  # built as "@bot[:mpd_musicfolder] + @bot[:youtube_downloadsubdir]"
  # In the default configuration it is: "/home/botmaster/music/downloadedfromyt/"
  #
  # If this directory does not exist it will automatically
  # be created by the bot when this plugin gets loaded.

  @settings[:youtube_tempsubdir] = "youtubeplugin/"
  # This is the RELATIVE path where the plugin stores its temporary files.
  # The full path is built as "@bot[:main_tempdir] + @bot[:youtube_tempsubdir]"
  # Therefore this path must NOT be a relative path and must NOT be set to a
  # subdirectory of the directory where MPD stores its files.
  # In the default configuration it is: "/home/botmaster/temp/youtubeplugin/"
  #
  # If this directory does not exist it will automatically
  # be created by the bot when this plugin gets loaded.

  @settings[:youtube_stream] = nil
  # Set this to another value then nil in order to NOT download
  # files from youtube but to stream them. Note that MPD will still
  # download the files and this will result in supermega gaps :)
  # So don't use this feature. You have been warned.
  
  @settings[:youtube_youtubedl] = "/home/botmaster/src/youtube-dl"
  # Path to the youtube-dl binary. The default value should be fine if
  # you used the official mumble-ruby-pluginbot tutorial.
  # If you instead installed youtube-dl via system packages,
  # change it to "/usr/bin/youtube-dl".
  ###########################
  
  @settings[:youtube_to_mp3] = nil
  # If this is set to something other than nil ffmpeg/avconv
  # will try to convert downloaded audio into mp3 (190kBit)
  # The default is nil. Downloaded files will be stored at best quality
  ###########################
  
  @settings[:youtube_youtubedl_options] = ""
  # Additional options to youtube-dl.
  # You can add for example "-r 2.5M" and the downloadspeed
  # will be limited to 2.5 Mb/s. "--restrict-filenames" transformes
  # filenames into a safe charset. By default this is empty,
  # but it is not a bad idea to restrict filenames.
  ###########################
  
  @settings[:youtube_commandlineprefixes] = ""
  # Additional prefixes for the command which downloads the files
  # via youtube-dl.
  # For example you may set this to "ionice -c 3" presumed the
  # package util-linux is installed (on Debian).
  # In this case the command would only write to the filesystem if no
  # other process is writing, so only if the filesystem is idle.
  
  @settings[:youtube_maxresults] = 200
  # Limits results for the .yts command to the given number because
  # depending on the search string the plugin may run for a very
  # long time and return several thousand results.
  
  ###########################
  # Soundcloud plugin: ######
  ###########################
  @settings[:soundcloud_downloadsubdir] = "downloadedfromsc/"
  # This is the RELATIVE path where the plugin stores its permanent files.
  # Note that you also need to set @settings[:mpd_musicfolder] in the next
  # section of the "Mpd plugin", because the complete path is
  # built as "@bot[:mpd_musicfolder] + @bot[:soundcloud_downloadsubdir]"
  # In the default configuration it is: "/home/botmaster/music/downloadedfromsc/"
  #
  # If this directory does not exist it will automatically
  # be created by the bot when this plugin gets loaded.

  @settings[:soundcloud_tempsubdir] = "soundcloudplugin/"
  # This is the RELATIVE path where the plugin stores its temporary files.
  # The full path is built as "@bot[:main_tempdir] + @bot[:soundcloud_tempsubdir]"
  # Therefore this path must NOT be a relative path and must NOT be set to a
  # subdirectory of the directory where MPD stores its files.
  # In the default configuration it is: "/home/botmaster/temp/soundcloudplugin/"
  #
  # If this directory does not exist it will automatically
  # be created by the bot when this plugin gets loaded.

  @settings[:soundcloud_youtubedl] = "/home/botmaster/src/youtube-dl"
  # Path to the youtube-dl binary. The default value should be fine if
  # you used the official mumble-ruby-pluginbot tutorial.
  # If you instead installed youtube-dl via system packages,
  # change it to "/usr/bin/youtube-dl".
  ###########################
  
  @settings[:soundcloud_to_mp3] = nil
  # If this is set to something other than nil ffmpeg/avconv
  # will try to convert downloaded audio into mp3 (190kBit)
  # The default is nil. Downloaded files will be stored at best quality
  ###########################
  
  @settings[:soundcloud_youtubedl_options] = ""
  # additional options to youtube-dl 
  # you can add "-r 2.5M" and the downloadspeed will be limited to 2.5 Mb/s 
  # "--restrict-filenames" transformes filenames into a safe charset 
  # by default this is empty, but it is not a bad idea to restrict filenames.
  ##########################
  
  @settings[:soundcloud_commandlineprefixes] = ""
  # Additional prefixes for the command which downloads the files
  # via youtube-dl.
  # For example you may set this to "ionice -c 3" presumed the
  # package util-linux is installed (on Debian).
  # In this case the command would only write to the filesystem if no
  # other process is writing, so only if the filesystem is idle.
  
  ###########################
  # Bandcamp plugin: ######
  ###########################
  @settings[:bandcamp_downloadsubdir] = "downloadedfrombc/"
  # This is the RELATIVE path where the plugin stores its permanent files.
  # Note that you also need to set @settings[:mpd_musicfolder] in the next
  # section of the "Mpd plugin", because the complete path is
  # built as "@bot[:mpd_musicfolder] + @bot[:soundcloud_downloadsubdir]"
  # In the default configuration it is: "/home/botmaster/music/downloadedfrombc/"

  @settings[:bandcamp_tempsubdir] = "bandcampplugin/"
  # This is the RELATIVE path where the plugin stores its temporary files.
  # The full path is built as "@bot[:main_tempdir] + @bot[:soundcloud_tempsubdir]"
  # Therefore this path must NOT be a relative path and must NOT be set to a
  # subdirectory of the directory where MPD stores its files.
  # In the default configuration it is: "/home/botmaster/temp/bandcampplugin/"

  @settings[:bandcamp_youtubedl] = "/home/botmaster/src/youtube-dl"
  # Path to the youtube-dl binary. The default value should be fine if
  # you used the official mumble-ruby-pluginbot tutorial.
  # If you instead installed youtube-dl via system packages,
  # change it to "/usr/bin/youtube-dl".
  ###########################
  
  @settings[:bandcamp_to_mp3] = nil
  # If this is set to something other than nil ffmpeg/avconv
  # will try to convert downloaded audio into mp3 (190kBit)
  # The default is nil. Downloaded files will be stored at best quality
  ###########################
  
  @settings[:bandcamp_youtubedl_options] = ""
  # additional options to youtube-dl 
  # you can add "-r 2.5M" and the downloadspeed will be limited to 2.5 Mb/s 
  # "--restrict-filenames" transformes filenames into a safe charset 
  # by default this is empty, but it is not a bad idea to restrict filenames.
  ##########################
  
  @settings[:bandcamp_commandlineprefixes] = ""
  # Additional prefixes for the command which downloads the files
  # via youtube-dl.
  # For example you may set this to "ionice -c 3" presumed the
  # package util-linux is installed (on Debian).
  # In this case the command would only write to the filesystem if no
  # other process is writing, so only if the filesystem is idle.

  ###########################
  # Ektoplazm plugin:  ######
  ###########################
  @settings[:ektoplazm_downloadsubdir] = "ektoplazm/"
  # This is the RELATIVE path where the plugin stores its permanent files.
  # Note that you also need to set @settings[:mpd_musicfolder] in the next
  # section of the "Mpd plugin", because the complete path is
  # built as "@bot[:mpd_musicfolder] + @bot[:soundcloud_downloadsubdir]"
  # In the default configuration it is: "/home/botmaster/music/ektoplazm/"
  #
  # If this directory does not exist it will automatically
  # be created by the bot when this plugin gets loaded.

  @settings[:ektoplazm_tempsubdir] = "ektoplazmplugin/"
  # This is the RELATIVE path where the plugin stores its temporary files.
  # The full path is built as "@bot[:main_tempdir] + @bot[:soundcloud_tempsubdir]"
  # Therefore this path must NOT be a relative path and must NOT be set to a
  # subdirectory of the directory where MPD stores its files.
  # In the default configuration it is: "/home/botmaster/temp/ektoplazmplugin/"
  #
  # If this directory does not exist it will automatically
  # be created by the bot when this plugin gets loaded.

  ###########################
  # Mpd plugin: #############
  ###########################
  @settings[:mpd_musicfolder] = "/home/botmaster/music/"
  # This is not used in the "Mpd plugin" itself but is needed by
  # other plugins.
  # Set this to the same path that you set in your mpd config
  # file in the variable music_directory.

  ###########################
  # Control plugin: #########
  ###########################
  @settings[:control_historysize] = 20
  # Sets the history size to 20 commands.
  # This is also the default value when commented out.
  
  
  #This template must always contain one %s string.
  @settings[:mpd_template_comment_disabled] = "<b>Artist: </b>DISABLED<br />"\
                                            + "<b>Title: </b>DISABLED<br />" \
                                            + "<b>Album: </b>DISABLED<br /><br />" \
                                            + "<b>Write %shelp to me, to get a list of my commands!"
  #This template must always contain four %s strings.
  @settings[:mpd_template_comment_enabled] = "<b>Artist: </b>%s<br />"\
                                           + "<b>Title: </b>%s<br />" \
                                           + "<b>Album: </b>%s<br /><br />" \
                                           + "<b>Write %shelp to me, to get a list of my commands!</b>"
  ###########################
end
