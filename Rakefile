require 'rubygems'

TEST_APP_NAME = 'TestApp.mxml'
ROOT_DIR = File.dirname(__FILE__)

def get_executable(executable)
  if RUBY_PLATFORM =~ /mswin32/
    executable << '.exe'
  end
  executable
end

task :default => [:build]

desc "Build the framework"
task :build do
  system("compc +configname=air -load-config+=framework/ruboss-config.xml")
end

desc "Compile and run test application"
task :test => ["test:build", "test:run"]

namespace :test do  
  desc "Compile test application"
  task :build do
    project_path = File.join(ROOT_DIR, "tests/src", TEST_APP_NAME)
    target_project_path = File.join(ROOT_DIR, "tests/bin", TEST_APP_NAME.sub(/.mxml$/, '.swf'))
    source_path = [File.join(ROOT_DIR, "framework/src"), File.join(ROOT_DIR, "tests/src")]
    libs = Dir.glob(File.join(ROOT_DIR, 'tests/lib', '*.swc'))
    
    cmd = "#{get_executable('mxmlc')} +configname=air -library-path+=#{libs.join(',')} " << 
      "-output #{target_project_path} -debug=true -source-path=#{source_path.join(',')}" <<
      " #{project_path}"
    if !system(cmd)
      puts "failed to compile test application"
    end
  end
  
  desc "Run the application"
  task :run do
    project_path = File.join(ROOT_DIR, "tests/src", TEST_APP_NAME)
    target_project_air_descriptor = project_path.sub(/.mxml$/, '-app.xml')
    
    if !system("#{get_executable('adl')} #{target_project_air_descriptor} #{ROOT_DIR}")
      puts "failed to run test application"
    end
  end
end
