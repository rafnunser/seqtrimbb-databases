#!/usr/bin/env ruby

require 'digest'
require 'json'
#New hash
databases_info = {}
#Dirs
db_path = Dir.pwd
databases_paths = Dir[File.join(db_path,'*')].select { |dir| File.directory?(dir) }
#Store available databases in repository
databases_info['databases'] = databases_paths.map{ |dir| File.basename(dir) }
#Databases date
begin
  ls_call = IO.popen("ls --full-time #{db_path}")
rescue Exception => e
  STDERR.puts "ERROR. Ls:\n #{e}"
  exit(-1)
end
ls_out = ls_call.readlines.map(&:chomp).drop(1)
result = {}           
ls_out.map! { |line| line.split(/\s+/).drop(5) }.each do |array|
  result[array.last] = array.take(2).join('').gsub(/-|:/,'').to_i
end
ls_call.close
#For each database
databases_paths.each do |database|
  db_hash = {}
  db_hash['date'] = result[File.basename(database)]
  db_hash['files_checksum'] = {}
  Dir[File.join(database,"*.fasta*")].sort.each do |entry|
    db_hash['files_checksum'][File.basename(entry)] = Digest::MD5.file(entry).hexdigest
  end
  databases_info[File.basename(database)] = db_hash
end
#Check for changes
file_to_save = File.join(db_path,"repository_databases_info.json")

if File.exists?(file_to_save)
  old_info = JSON.parse(File.read(file_to_save))
  if old_info != databases_info
	puts "Repository JSON is obsolete: Saving file"
    File.delete(file_to_save)  
    File.open(file_to_save,"w") do |f|
      f.write(JSON.pretty_generate(databases_info))
    end
  end   
else
	puts "Repository JSON not found: Saving file"
    File.open(file_to_save,"w") do |f|
      f.write(JSON.pretty_generate(databases_info))
    end
end
