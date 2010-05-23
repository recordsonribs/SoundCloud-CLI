require 'rubygems'

require 'commander/import' # Collection of CLI in a API - http://visionmedia.github.com/commander/
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

# Load username and password if we have them from sc.xml
if File.exist?('sc.xml')
  conf = Document.new File.new('sc.xml')
  uname = XPath.first( conf, "//username" ).text
  pword = XPath.first( conf, "//password" ).text
else
  uname = ask("SoundCloud Username: ")
  pword = password
  
  # Output to file
end

command :upload do |c|
  c.syntax = 'sc upload [tracks or track directory]'
  c.description = 'Uploads file(s) specified on command line to Soundcloud.'
  
  # Array of SoundCloud Files
  upfiles = Array.new

  c.when_called do |args, options|
    args.each do | arg |
      if File.directory?(arg)
         Dir.foreach(arg) do |f| 
           if File.extname(f) == '.flac'
             file = SCFile.new
             file.filename = f
             file.title = 'Test'
             file.bpm = '0'
             upfiles.push(file)   
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
    
    if agree("Are these files going to be part of a set? ")
      # We could make a few guesses here from reading the files, ie album tags
      set_title = ask("Title: ")
      set_desc = ask("Description:")
      set_genre = ask("Genre: ")
      set_label = ask("Record Label: ")
      set_date = ask_for_date("Release Date (yy-mm-dd): ")
      set_label = ask("EAN/UPC: ")
      set_buy = ask("Buy this set link: ") { |q| q.validate = /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix }
      set_tags = ask_for_array("Tags (seperated by space): ")
      
      # Sort out license     
      choose do |menu|
        menu.prompt = "Please choose the license for this set?  "     
        menu.choices(:all_rights_reserved, :cc_by) do |chosen|
          set_license = chosen
        end
      end
    end # End setup set
    
  end # Action
end