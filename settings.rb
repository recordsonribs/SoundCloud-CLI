def load_settings(setting)
  puts "Using settings for '#{setting}'."
  case setting
  when :cli
    {
      :site                => "http://api.sandbox-soundcloud.com",
      
      :consumer_key        => 'YOUR_CONSUMER_KEY',
      :consumer_secret     => 'YOUR_CONSUMER_SECRET',
      
      :access_token_key    => 'AUTHORIZED_TOKEN_KEY',
      :access_token_secret => 'AUTHORIZED_TOKEN_SECRET',
    }
  else
    raise "No settings for #{setting}"
  end
end
