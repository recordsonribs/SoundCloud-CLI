#!/usr/bin/ruby
# ^ enter your ruby location above
=begin
= SoundCloud Command Line Interface

An easy to use command line interface to SoundCloud that makes uploading easy.

== Requirements
- rubygems
- flacinfo
- ogginfo
- mp3info
- soundcloud
- commander
=end


begin
  require 'rubygems'
rescue LoadError
  puts "You don't seem to have installed rubygems - how do you do anything?"
  puts "See http://docs.rubygems.org/read/chapter/3 for details"
  exit (1)
end

# The script requires quite a few gems, so let the user know if they don't have them 
# rather than just dumping them back to the command-line in a flurry of error messages
# TODO the libraries for the various file types should be included on the fly, but for now
%w(soundcloud flacinfo commander commander/import mp3info ogginfo).each {|x|
  begin
    require x
  rescue LoadError
    puts "You don't seem to have installed the required gem #{x}"
    puts "Try 'sudo gem install #{x}' to install"
    exit (1)
  end
}

program :name, 'Soundcloud CLI'
program :version, '0.1'
program :description, 'Command-line interface to SoundCloud.'
program :help, 'Author', 'Alex Andrews (alex@recordonribs.com)'
program :int_message, 'Interupted.'

command :upload do |c|
  c.syntax = 'sc upload [tracks or track directory]'
  c.description = 'Uploads file(s) specified on command line to Soundcloud, reading the tags from FLAC files.'
  c.example 'Scans directory /home/ror/flac/album for files and uploads them to SoundCloud.','sc upload /home/ror/flac/album'
  c.example 'Uploads flac file /home/ror/flac/album/01.flac to SoundCloud.','sc upload /home/ror/flac/album/01.flac'
  
  c.option '--silent','No output'
  c.option '--set STRING', String, 'Name of playlist'
  
  c.when_called do |args, options|
    args.each do | arg |
      file_path = arg
        
      if ! File.exist?(file_path)
        puts "#{file_path} does not exist"
        exit (1)
      end
            
      SC.connect(:sc) do |soundcloud|
          # If they have specified a playlist name, then make that playlist
          if options.set
            puts "Uploading set #{options.set}"
            pl = soundcloud.Playlist.new
            pl.title = options.set
          end
          
          if File.directory?(file_path)
            puts "Scanning directory #{file_path}"

            Dir.foreach(file_path) do |f|
              path = File.expand_path(File.join(file_path,f))
              dir = File.basename(file_path)
              tags = read_tags(path)
              
              print "Uploading #{flac.tags['TITLE']}..."
              $stdout.flush

              track = soundcloud.Track.create(
                       :title      => '',
                       :downloadable => true,
                       :license => pl.license,
                       :genre => pl.genre,
                       :sharing => pl.sharing,
                       :release => pl.release,
                       :description => '',
                       :label_name => pl.label_name,
                       :streamable => true,
                       :track_type => 'original',
                       :purchase_url => pl.purchase_url,
                       :release_day => pl.release_day,
                       :release_month => pl.release_month,
                       :release_year => pl.release_year,
                       :tag_list => pl.tag_list,
                       :artwork_data => File.new("#{file_path}/Artwork.jpg"),
                       :asset_data => File.new(path)
                       )

               pl.tracks << track
               puts "done"
               $stdout.flush
            end    
          else
            puts "Scanning file #{file_path}"
            
            path = File.expand_path(file_path)
            dir = File.basename(file_path)
            tags = read_tags(path)
            print 'Uploading file...'
            track = soundcloud.Track.create(
                     :title      => '',
                     :downloadable => true,
                     :license => pl.license,
                     :genre => pl.genre,
                     :sharing => pl.sharing,
                     :release => pl.release,
                     :description => '',
                     :label_name => pl.label_name,
                     :streamable => true,
                     :track_type => 'original',
                     :purchase_url => pl.purchase_url,
                     :release_day => pl.release_day,
                     :release_month => pl.release_month,
                     :release_year => pl.release_year,
                     :tag_list => pl.tag_list,
                     :artwork_data => File.new("#{file_path}/Artwork.jpg"),
                     :asset_data => File.new(path)
                     )
              print "done \n"
              puts "'#{track.title}' is now available at #{track.permalink_url}"
              
              # If they have specified a playlist, then add track to it, remembering we may have many tracks
              if options.set 
                pl.tracks << track
              end
          end
          
          if options.set
            print "Attempting to save playlist #{pl.title}..."
            $stdout.flush
            pl.save
            puts "saved"
            $stdout.flush
          end
      end
    end
  end
end

command :release do |c|
  c.syntax = 'sc release [directory]'
  c.description = 'Uploads files from specified directory to Soundcloud, reading the tags from files, but assumes these are part of a single release.'
  c.example 'Scans directory /home/ror/flac/album for a release and uploads them to SoundCloud.','sc release /home/ror/flac/album'
  
  c.when_called do |args, options|
    args.each do | arg |
      file_path = arg
            
      if ! File.exist?('file_path')
        puts "#{file_path} does not exist"
        exit (1)
      end
      
      if ! File.directory?('file_path')
        puts "#{file_path} is not a directory, release mode needs to have a directory to upload"
        exit (1)
      end
      
      Dir.foreach(file_path) do |f|
          path = File.expand_path(File.join(file_path,f))
          dir = File.basename(file_path)
          tags = read_tags(path)
          
          # We assume the first track gives us the details of the playlist
      end
    end
  end
end

# Reads the tags from any file given, returns a tag array
# Uses various libraries to do so
def read_tags(file)
  ext = File.extname(file)
  
  case ext
    when '.flac'
      flac = FlacInfo.new(file)
    when '.ogg'
      
    when '.mp3'
    else 
      puts "#{file} is not a recognised file type (#{ext})"
  end
  
  return tags
end

# Original coding thanks to Hannes Tydén (hannes@soundcloud.com)
# 
def load_settings(setting)
  case setting
  when :sc
    {
      :site                => "http://api.soundcloud.com",
      
      :consumer_key        => '',
      :consumer_secret     => '',
      
      :access_token_key    => '',
      :access_token_secret => '',
    }
  else
    raise "No settings for #{setting}"
  end
end

# Original coding thanks to Hannes Tydén (hannes@soundcloud.com)
module SC
  def self.connect(setting=nil)
    setting ||= ((s = ENV['SETTING']) && s.to_sym) || :sandbox
    
    settings = load_settings(setting)
    consumer = Soundcloud.consumer(settings[:consumer_key], settings[:consumer_secret], settings[:site])
    
    begin
      unless settings[:access_token_key] && settings[:access_token_secret]
        request_token = consumer.get_request_token(:oauth_callback => settings[:token_callback])
        
        if (oauth10a = request_token.respond_to?(:callback_confirmed?) && request_token.callback_confirmed?)
          puts "OAuth 1.0a detected"
        end
        
        authorize_url = request_token.authorize_url(:oauth_callback => settings[:authorize_callback] || '')
        puts "Opening: #{authorize_url}"
        puts `open '#{authorize_url}'`
        
        if oauth10a
          puts "What is the 'oauth_verifier'?"
          oauth_verifier = STDIN.gets.chomp
          
          access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
        else
          puts "Authorized?"
          STDIN.gets
          
          access_token = request_token.get_access_token
        end
        
        puts <<-ADD.gsub(/^\s+/, "")
        For future use of this authorization, add"
        
        :access_token_key    => '#{access_token.token}',
        :access_token_secret => '#{access_token.secret}',
        
        to the :#{setting} settings hash in settings.rb.
        ADD
      else
        # puts "Using"
        # puts "token_key    #{settings[:access_token_key]}"
        # puts "token_secret #{settings[:access_token_secret]}"
        access_token = OAuth::AccessToken.new(consumer, settings[:access_token_key], settings[:access_token_secret])
      end
      
      if access_token
        soundcloud = Soundcloud.register({:access_token => access_token, :site => settings[:site]})
        if block_given?
          yield soundcloud
        else
          soundcloud
        end
      else
        puts "No access token available."
      end
    rescue OAuth::Unauthorized
      puts "Unauthorized"
    end
  end
end