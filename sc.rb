require 'rubygems'

gem 'flacinfo-rb'

require 'commander/import' # Collection of CLI in a API - http://visionmedia.github.com/commander/
require 'flacinfo' # FlacInfo library for reading tags from FLAC files
require 'rexml/document'

include REXML

class SCFile  
  @@files_count = 0
  
  attr_writer :filename, :type, :title,:bpm
  attr_reader :filename, :type, :title,:bpm, :files_count
  
  def initialize()
      @@files_count += 1
  end
  
end

program :name, 'Soundcloud CLI'
program :version, '0.1'
program :description, 'Command-line interface to SoundCloud.'
program :help, 'Author', 'Alex Andrews (alex@recordonribs.com)'
program :int_message, 'Interupted, bailing.'

# Load username and password if we have them from sc.xml
if File.exist?('sc.xml')
  conf = Document.new File.new('sc.xml')
  uname = XPath.first( conf, "//username" ).text
  pword = XPath.first( conf, "//password" ).text
  license = XPath.first( conf, "//license" ).text
else
  uname = ask("SoundCloud Username: ")
  pword = password
  
  # Output to file
end

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

command :setup do |c|
  c.syntax = 'sc setup'
  c.description = 'Sets default settings for SoundCloud upload and writes them to configuration file.'
end

command :download do |c|
  c.syntax = 'sc download [title]'
  c.description = 'Attempts to download the file from SoundCloud with the title specified.'
end