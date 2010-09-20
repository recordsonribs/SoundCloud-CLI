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
%w(soundcloud flacinfo commander commander/import mp3info ogginfo parseconfig).each do |x|
  begin
    require x
  rescue LoadError
    puts "You don't seem to have installed the required gem #{x}"
    puts "Try 'sudo gem install #{x}' to install"
    exit (1)
  end
end

# An abstraction to upload the specified file to SoundCloud
# Mainly done to comply with the logic of DRY
def upload_track(file)
  tags = read_tags(file)
  print "Uploading #{tags.artist} - #{tags.title}..."
  SC.connect(:sc) do |soundcloud|
  end
end

# Reads the tags from any file given, returns a tag array
# Uses various libraries to do so
def read_tags(file)
  ext = File.extname(file) 
  tags = Hash.new
 
  case ext
    when '.flac'
      flac = FlacInfo.new(file)
      flac.tags.each do |tag, var|
        tags[tag.downcase] = var
      end
    when '.ogg'
      ogg = OggInfo.open(file)
      ogg.tag.each do |tag, var|
        tags[tag.downcase] = var
      end
    when '.mp3'
      mp3 = Mp3Info.open(file)
      mp3.tag.each do |tag, var|
        tags[tag.downcase] = var
      end
    else 
      puts "#{file} is not a recognised file type (#{ext})"
  end
  
  return tags
end

# Original coding thanks to Hannes Tydén (hannes@soundcloud.com)
def load_settings()
  if ! File.exist?("#{ENV['HOME']}/.sc")
    puts "No configuration file set up, please enter details now"
    exit(1)
  end
  
  $settings = ParseConfig.new("#{ENV['HOME']}/.sc")
end

# Original coding thanks to Hannes Tydén (hannes@soundcloud.com)
module SC
  def self.connect(setting=nil)
    setting ||= ((s = ENV['SETTING']) && s.to_sym) || :sandbox
    
    #settings = load_settings(setting)
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