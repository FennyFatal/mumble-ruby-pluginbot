require 'open-uri'
require_relative '../helpers/StreamCheck.rb'

class Radiostream < Plugin

  def init(init)
    super
    if ( @@bot[:mpd] ) && ( @@bot[:messages] ) && ( @@bot[:radiostream].nil? )
      logger("INFO: INIT plugin #{self.class.name}.")
      @@bot[:radiostream] = self
      begin
        @xspf = require 'crack'         #parse xspf playlists only if crack gem is installed
      rescue
        logger "if you install crack gem radiostream plugin also can parse xspf stream playlists." if @xspf == false
      end
      @keylist = Array.new
      @radiolist =  Hash.new{|hsh,key| hsh[key] = [] }
      @radiofeed = []
    end
    return @@bot
  end

  def name
    if ( @@bot[:mpd].nil? ) || ( @@bot[:messages].nil? ) || ( @@bot[:radiostream].nil?)
      "false"
    else
      self.class.name
    end
  end

  def help(h)
    h << "<hr><span style='color:red;'>Plugin #{self.class.name}</span><br>"
    h << "<b>#{Conf.gvalue("main:control:string")}radiostream URL</b> - #{I18n.t("plugin_radiostream.help.radiostream")}<br>"
    h << "<b>#{Conf.gvalue("main:control:string")}radioupdate</b> - #{I18n.t("plugin_radiostream.help.radioupdate")}<br>" if @xspf == true
    h << "<b>#{Conf.gvalue("main:control:string")}radiocategories</b> - #{I18n.t("plugin_radiostream.help.radiocategories", :controlstring => Conf.gvalue("main:control:string"))}<br>" if @xspf == true
    h << "<b>#{Conf.gvalue("main:control:string")}radiocategory</b> <i>search</i> - #{I18n.t("plugin_radiostream.help.radiocategory")}<br>" if @xspf == true
    h << "<b>#{Conf.gvalue("main:control:string")}radioselect</b> <i>search number</i> - #{I18n.t("plugin_radiostream.help.radioselect", :controlstring => Conf.gvalue("main:control:string"))}<br>" if @xspf == true
    h << "<b>#{Conf.gvalue("main:control:string")}choose</b> - #{I18n.t("plugin_radiostream.help.choose")}<br>"
    h << "<b>#{Conf.gvalue("main:control:string")}choose <i>number</i></b> - #{I18n.t("plugin_radiostream.help.choosenumber")}<br>"
    h << I18n.t("plugin_radiostream.help.info")
  end

  def handle_chat(msg, message)
    super
    if message.start_with?("radiostream <a href=") || message.start_with?("<a href=")
      link = msg.message.match(/http[s]?:\/\/(.+?)\"/).to_s.chop
      @keylist.delete_if { |key| key[:user] == msg.actor }              #delete last search for this user
      Thread.new do
        user = msg.actor
        Thread.current["user"]=msg.username
        Thread.current["process"]="radiostream"
        add_link( link, user )
        results = (@keylist.count { |key| key[:user] == msg.actor })
        if results > 1 then
          messageto(msg.actor, I18n.t("plugin_radiostream.radiostream.results", :results => results) )
        else
          add = ""
          @keylist.each do |key|
            if key[:user]==user then
              add = key[:link]
            end
          end
          if add != "" then
            @@bot[:mpd].add(add)
            messageto(msg.actor, I18n.t("plugin_radiostream.radiostream.added", :added => add) )
          else
            messageto(msg.actor, I18n.t("plugin_radiostream.radiostream.noradio"))
          end
        end
      end
    end

    if message == "choose"
      counter = 0
      output = "#{I18n.t("plugin_radiostream.choose.can")}<br><table>"
      @keylist.each do |key|
        if key[:user] == msg.actor then
          output << ("<tr><td>#{counter.to_s}</td><td>#{key[:link]}</td></tr>")
          counter += 1
        end
      end
      output << "</table>"
      output = I18n.t("plugin_radiostream.choose.cant") if counter == 0
      messageto(msg.actor, output)
    end

    if message.match (/choose (?:[\d{1,3}\ ?])+/)
      begin
        msg_parameters = message.split[1..-1].join(" ")
        id_list = msg_parameters.match(/(?:[\d{1,3}\ ?])+/)[0].split

        chooselist = Array.new                                          #generate chooselist first
        @keylist.each do |key|
          if key[:user] == msg.actor then
            chooselist << key[:link]
          end
        end

        id_list.each do |id|
          @@bot[:mpd].add(chooselist[id.to_i])
          messageto(msg.actor, I18n.t("plugin_radiostream.choose.added", :item => chooselist[id.to_i]))
        end

      rescue
        messageto(msg.actor, I18n.t("plugin_radiostream.choose.not_exist"))
      end
    end

    if message == "radioupdate" && @xspf
      url = 'http://www.steamcast.com/sbin/rss_feed.rss'
      @radiolist = Hash.new{|hsh,key| hsh[key] = [] }
      open(url) do |rss|
        @radiofeed = Crack::XML.parse(rss)["rss"]["channel"]["item"]
        @radiofeed.each do |item|
          item["category"].split(/\W+/).each do |cat|
            @radiolist[cat].push item["title"]
          end
        end
      end
      messageto(msg.actor, I18n.t("plugin_radiostream.radioupdate"))
    end

    if message == "radiocategories" && @xspf
      categories= ""
      bold = false
      @radiolist.each do | key, value|
          if bold == false then
            categories += "#{key}, "
          else
            categories += "<b>#{key}</b>, "
          end
          bold = !bold
      end
      if categories == "" then
        messageto(msg.actor, I18n.t("plugin_radiostream.radiocategories.nofound"))
      else
        messageto(msg.actor, I18n.t("plugin_radiostream.radiocategories.found", :item => categories))
      end
    end

    if message[0..12] == "radiocategory" && @xspf
      reply = "<table><th><td>#{I18n.t("plugin_radiostream.radiocategory.station")}</td><td>#{I18n.t("plugin_radiostream.radiocategory.description")}</td></th>"
      nr = 0
      @radiolist.each do |key, values|
        if key.to_s.downcase.include?(message.split[1].downcase)
          values.each do |value|
            nr += 1
            reply << "<tr><td>#{nr}</td><td>#{value}</td></tr>"
          end
        end
      end
      reply << "</table>"
      messageto(msg.actor, "#{reply}")
    end

    if message[0..10] == "radioselect" && @xspf
      nr = 0
      @radiolist.each do |key, values|
        if key.to_s.downcase.include?(message.split[1].downcase)
          values.each do |value|
            nr += 1
            if nr == message.split[2].to_i
              messageto(msg.actor, value)
              @radiofeed.each do |item|
                if item["title"] == value then
                  link = item["link"]
                  @keylist.delete_if { |key| key[:user] == msg.actor }              #delete last search for this user
                  Thread.new do
                    user = msg.actor
                    Thread.current["user"]=msg.username
                    Thread.current["process"]="radioselect"
                    add_link( link, user )
                    results = (@keylist.count { |key| key[:user] == msg.actor })
                    if results > 1 then
                      messageto(msg.actor, I18n.t("plugin_radiostream.radioselect.multiple", :results => results))
                    else
                      add = ""
                      @keylist.each do |key|
                        if key[:user]==user then
                          add = key[:link]
                        end
                      end
                      if add != "" then
                        @@bot[:mpd].add(add)
                        messageto(msg.actor, I18n.t("plugin_radiostream.radioselect.added", :item => add))
                      else
                        messageto(msg.actor, I18n.t("plugin_radiostream.radioselect.none"))
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

  end

  private

  def add_link(link, user)

    decoded = false
    logger link
    file = `curl -g -L --max-time 3 "#{link}" `             #Load some data from link
    streaminfo = StreamCheck.new                            #init StreamCheck

    info = streaminfo.checkmp3(file)                        #check if mp3
    if info[:verified] then                                 #is mp3-stream?
      info[:link] = link                                    #add link to info
      decoded = true                                        #set decoded to true to prevent other checks
    end

    if !decoded                                             #if it is no mp3 stream
      info = streaminfo.checkopus(file)                     #check if ogg
      if info[:verified] then                               #is ogg-stream?
        info[:link] = link                                  #add link to info
        decoded = true                                      #set decodet to true to prevent other checks
      end
    end

    if !decoded                                             #if it is no ogg stream
      info = streaminfo.checkaac(file)                      #check if mpeg2aac
      if info[:verified] then                               #is aac-stream?
        info[:link] = link                                  #add link to info
        decoded = true                                      #set decodet to true to prevent other checks
      end
    end

    if ( file[0..9] == "[playlist]" ) && !decoded           #if still not decoded check if is a .pls link
                                                            # seems to be an .pls link
      file.each_line do |line|
        if line.match (/File[0-9]{1,2}=.+/)                 #if a link found run check recursive
          add_link(line.sub(/File[0-9]{1,2}=/, '').strip, user)
        end
      end
    end

    if ( file[0..4] == "<?xml" ) && ( @xspf == true ) && !decoded
                                                            #if still not decoded check if it is an xml file and crack gem is installed
      begin
        tracks = Crack::XML.parse(file)["playlist"]["trackList"]["track"]
        if tracks.size > 1
          tracks.each do |track|
            add_link(track["location"], user)
          end
        else
          add_link(tracks["location"], user)
        end
      rescue
        # no xspf!
      end
    end

    if !decoded                                             #if still not decoded test as m3u link
      file.each_line do |line|
        if ( line.start_with? "http://" ) || ( line.start_with? "https://")
          add_link(line.strip, user)                        #if it contains links in m3u manner
        end
      end
    end

    if ( decoded == true )                                  #if decoded add info to keylist
      info[:user]=user
      @keylist << info
    end
  end
end
