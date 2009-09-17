#!/usr/bin/env ruby -rubygems
%w(yaml haml sequel sinatra).each { |lib| require lib }

CFG = YAML.load_file( YAML.load_file(File.dirname(__FILE__) + '/config.yml')[:project_config] )

#-----------------------------
# DB setup
#-----------------------------
DB = Sequel.connect('sqlite://ppp-server.db')

DB.create_table :commands do
  String :command, :primary_key => true
  String :path
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
  @commands = Command.all
  haml :index
end

post '/' do
  DB_refresh()
  @commands = Command.all
  haml :index
end

post '/run' do
  params[:commands].split(';').each do |command|
    record = Command[:command => command]
    # Return 501 (Not Implemented) if command not found
    status 501 and return command if execute.nil?
    # Return 500 (Server Error) if command does not exit with 0
    status 500 and return command unless system(record.path + record.command)
  end

  status 200
  'true'
end

get '/run' do
  record = Command[:command => 'gen-preambles']
  #result = %x["#{record.path + record.command}"]
  #p result
  status 500 and return 'Error on gen-preambles' unless system(record.path + record.command)
  status 200 and return 'Ran gen-preambles'
end

#-----------------------------
# Helper Funcions
#-----------------------------
# Add any new scripts to database
def DB_refresh
  # Each Script Location (sloc)
  CFG[:file_structure][:scripts].each do |sloc|
    sloc = CFG[:file_structure][:root]+sloc
    # Open the directory and add any scripts to executable list
    Dir.open(sloc) do |dir|
      # Loop through each Script File (sfile) in the Script Location (sloc) location
      dir.each do |sfile|
        next if sfile == '.' or sfile == '..' or Command[:command => sfile]
        Command.insert(:command => sfile, :path => sloc)
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
    %title Script List
  %body
    Records Found:
    %br
    - @commands.each do |command|
      = command.command
      %br
    %form{ :action => '/', :method => :post}
      %input{ :type =>'submit' :value => 'Refresh'}
