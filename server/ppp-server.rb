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
  haml :push
end

post '/' do
  @records = DB[:commands].all
#  params[:keys].split(';').each do |key|
#    @records.push( DB[:commands][:key => key] )
#  end
  haml :push
end

__END__

@@index
!!!
%html
  %head
    %title Add Commands
  %body
    %form{ :action => '/', :method => :post}
      %label
        Key:
        %input{ :type => 'text', :name => 'key'}
      %label
        Command:
        %input{ :type => 'text', :name => 'command'}

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
