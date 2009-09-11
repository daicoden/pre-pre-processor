#!/usr/bin/env ruby -rubygems
%w(yaml haml sequel sinatra).each { |lib| require lib }

CFG = YAML.load_file(File.dirname(__FILE__) + '/config.yml')

#-----------------------------
# DB setup
#-----------------------------
DB = Sequel.connect('sqlite://ppp-server.db')

DB.create_table :commands do
  String :command, :primary_key => true
end unless DB.table_exists?(:commands)
#-----------------------------
# Models
#-----------------------------
class Command < Sequel::Model(DB[:commands])
end
#-----------------------------
# URI Processing
#-----------------------------
get '/' do
  @records = DB[:commands].all
  haml :index
end

post '/' do
  DB_refresh()
  @records = DB[:commands].all
  haml :index
end
#-----------------------------
# Helper Funcions
#-----------------------------
# Add any new scripts to database
def DB_refresh
  # Each Script File (sf)
  CFG[:file_structure][:scripts].each do |sf|
    # Open the directory and add any scripts to executable list
    Dir.open(CFG[:file_structure][:root]+sf) do |dir|
      # Loop through each File (f) in the Script File (sf) location
      dir.each do |f|
        next if f == '.' or f == '..' or DB[:commands][:command => f]
        DB[:commands].insert(:command => f)
      end
    end
  end
end
# When server starts check for new scripts
DB_refresh()

__END__

@@index
!!!
%html
  %head
    %title Add Commands
  %body
    Records Found:
    %br
    - @records.each do |record|
      = record[:command]
      %br
    %form{ :action => '/', :method => :post}
      %input{ :type =>'submit' :value => 'Refresh'}

@@push
!!!
%html
  %head
    %title
  %body
    Records Found:
    %br
    - @records.each do |record|
      = record[:command]
      %br
