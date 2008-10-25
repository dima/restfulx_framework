require 'rubygems'
require 'airake'

ENV["AIRAKE_ROOT"] ||= File.expand_path(File.dirname(__FILE__))
ENV["AIRAKE_ENV"] ||= "development"

task :default => [:build]

task :build do
  system("compc +configname=air -load-config+=framework/ruboss-config.xml")
end

task :test => ["air:test"]
