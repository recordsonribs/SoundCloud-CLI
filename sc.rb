require 'rubygems'

gem 'flacinfo-rb'

require 'commander/import' # Collection of CLI in a API - http://visionmedia.github.com/commander/
require 'flacinfo' # FlacInfo library for reading tags from FLAC files

require 'setup'

program :name, 'Soundcloud CLI'
program :version, '0.1'
program :description, 'Command-line interface to SoundCloud.'
program :help, 'Author', 'Alex Andrews (alex@recordonribs.com)'
program :int_message, 'Interupted, bailing.'

command :upload do |c|
  c.syntax = 'sc upload [tracks or track directory]'
  c.description = 'Uploads file(s) specified on command line to Soundcloud, reading the tags from FLAC files.'
  c.example 'Scans directory /home/ror/flac/album for FLAC files and uploads them to SoundCloud.','sc upload /home/ror/flac/album'
  c.example 'Uploads flac file /home/ror/flac/album/01.flac to SoundCloud.','sc upload /home/ror/flac/album/01.flac'
  
  # Array of SoundCloud Files
  upfiles = Array.new

  c.when_called do |args, options|
    args.each do | arg |
      if File.directory?(arg)
        print "Scanning directory #{arg}...\n"
        Dir.foreach(arg) do |f|
          if File.extname(f) == '.flac'
             flac = FlacInfo.new(File.join(arg,f))
             print "Uploading #{flac.tags['ARTIST']} - #{flac.tags['TITLE']}\n"
           end
         end
      else
        if !File.exist?(arg)
          puts "File #{arg} does not exist, bailing."
          exit
        end
        file = SCFile.new(arg,'flac')
        file.title = 'Test'
        file.bpm = '0'
        upfiles.push(file)
      end # File type
    end  # Argument parsing.
  end # Action
end
