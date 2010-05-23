require 'rubygems'

require 'commander/import' # Collection of CLI in a API - http://visionmedia.github.com/commander/
require 'rexml/document'

include REXML

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
  c.description = 'Uploads Flac specified on command line to Soundcloud.'
  
  c.when_called do |args, options|
   # Do something with the files here
  end
end