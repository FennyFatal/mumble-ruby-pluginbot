require 'google_music_api'
require 'json'

class GplayMusic < Plugin

  def init(init)
    super
    if ( @@bot[:mpd] ) && ( @@bot[:messages] ) && ( @@bot[:gplayMusic].nil? )
      logger("INFO: INIT plugin #{self.class.name}.")
      @@bot[:gplayMusic] = self
	@gplay = GoogleMusicApi::MobileClient.new
	un = Conf.gvalue("plugin:gplayMusic:username")
	pw = Conf.gvalue("plugin:gplayMusic:password")
	devid = Conf.gvalue("plugin:gplayMusic:devid")
	@gplay.login( un, pw, devid )
    end
    return @@bot
  end

  def name
    if ( @@bot[:mpd].nil? ) || ( @@bot[:messages].nil? ) || ( @@bot[:gplayMusic].nil?)
      "false"
    else
      self.class.name
    end
  end

  def help(h)
    h << "Hi"
  end

  def get_track(track)
     count = 0
     logger "INFO: Track found: #{track['title']} by #{track['artist']}"
     url = @gplay.get_track_stream(track['storeId'])
     @dest = "#{Conf.gvalue("plugin:mpd:musicfolder")+Conf.gvalue("plugin:youtube:folder:download")}"
     file = "#{track['artist']} - #{track['title']}"
     ending = 'mp3'
     system ("#{@prefixes} ffmpeg -i '#{url}' -acodec copy -metadata title='#{file}' '#{@dest}#{file}.#{ending}'") if !File.exist?("#{@dest}#{file}.#{ending}")
     "#{count+=1} <a href='#{url}'>#{track['artist']} - #{track['title']}.mp3</a>\n"
  end

  def get_podcast(track)
     count = 0
     logger "INFO: Track found: #{track['title']} by #{track['seriesTitle']}"
     url = @gplay.get_podcast_stream(track['episodeId'])
     logger "INFO: URL: #{url}"     
     @dest = "#{Conf.gvalue("plugin:mpd:musicfolder")+Conf.gvalue("plugin:youtube:folder:download")}"
     file = "#{track['seriesTitle']} - #{track['title']}"
     ending = 'mp3'
     system ("#{@prefixes} ffmpeg -i '#{url}' -acodec copy -metadata title='#{file}' '#{@dest}#{file.gsub(/[\']/, '\\\'')}.#{ending}'") if !File.exist?("#{@dest}#{file}.#{ending}")
     "#{count+=1} <a href='#{url}'>#{file}.mp3</a>\n"
  end

  def get_files(link)
    id = link.match(/(?<=\/)([^\/]+?[?])/).to_s.chop
    if link.include? "/r/m/"
      logger "INFO: GplayMusic playlist #{id}."
      tracks = @gplay.get_station_tracks(id)
      resp = ''
      if tracks != nil
        tracks.each do |t|
          logger "INFO: GplayMusic track #{t.inspect}."
        end
      end
      resp
    elsif link.include? "music/m/B" # Album
      resp = ''
      logger "INFO: GplayMusic album #{id}."
      tracks = @gplay.get_album_info(id)['tracks'].each do |track|
        resp << get_track(track)
      end
      resp
    elsif link.include? "music/m/D" # Podcast
      resp = ''
      logger "INFO: GplayMusic podcast #{id}."
      track = @gplay.get_podcast_episode(id)
      logger "INFO: #{track.inspect}"
      resp << get_podcast(track)
      resp
    elsif link.include? "music/m/T" # Track
      resp = ''
      logger "INFO: GplayMusic track #{id}."
      track = @gplay.get_track_info(id)
      resp << get_track(track)
      resp
    end
  end

  def handle_chat(msg, message)
    super
    if message.start_with?("gmlink <a href=") || message.start_with?("<a href=")
      link = msg.message.match(/http[s]?:\/\/(.+?)\"/).to_s.chop
      if ( link.include? "play.google.com/music/" ) then
        Thread.new do
          #local variables for this thread!
          actor = msg.actor
          name = msg.username
          logger "INFO: GplayMusic start Thread for #{name}."

          files = get_files(link)
          logger files
          if files.size > 0 then
            @@bot[:mpd].update(Conf.gvalue("plugin:youtube:folder:download").gsub(/\//,""))
              messageto(actor, I18n.t('plugin_youtube.db_update'))
            while @@bot[:mpd].status[:updating_db] do
              sleep 0.5
            end
            files.split("\n").each do |file|
              filename = file.match(/(?<=>)(.+<\/)/).to_s.chop.chop
              if filename.size > 0
                logger "INFO: GplayMusic #{filename}"
                begin
                  @@bot[:mpd].add(Conf.gvalue("plugin:youtube:folder:download")+"#{filename}")
                rescue
                  logger "INFO: GplayMusic #{filename} could not be added"
                end
                messageto(msg.actor, filename)
              end
            end
          end
        end
      end
    elsif message.split[0] == 'gms'
      search = message[4..-1]
      if !(( search.nil? ) || ( search == "" ))
        logger("INFO: searching #{search}.")
        Thread.new do
          Thread.current["user"]=msg.username
          Thread.current["process"]="gmusic (gms)"
          songs = @gplay.search(search, '1')
	  songs.each do |s|
	  #TODO: add menu for library addition.
	      logger("INFO: type #{s["type"]}")
	    if s["type"] == "1"
              logger("INFO: #{s.inspect}")
              messageto(msg.actor, "Found song: #{s["track"]["title"]} by #{s["track"]["artist"]} ")
            elsif s["type"] == "4"
#              logger("INFO: #{s.inspect}")
#              messageto(msg.actor, "Found station: #{s["station"]["seed"]} #{s["station"]["name"]}")
            else
#              logger("INFO: #{s.inspect}")
	    end
          end
          logger("INFO: got results for search: #{search}.")
	  logger("INFO: #{search.class}") 
	end
      end
    end
  end 
end
