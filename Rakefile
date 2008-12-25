require 'rubygems'

# how to update the gh-pages docs branch automatically
# 1. rake docs in master branch and commit
# 2. checkout gh-pages
# 3. git read-tree --prefix=master -u master
# 4. cp -r master/docs/api/* .
# 5. rm -rf master
# 6. git commit
# 7. git checkout master

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
  libs = Dir.glob(File.join(ROOT_DIR, 'tests/lib', '*.swc'))
  system("#{get_executable('compc')} +configname=air -load-config+=framework/ruboss-config.xml -library-path+=#{libs.join(',')}")
end

desc "Compile and run test application"
task :test => ["test:build", "test:run"]

desc "Build API documentation"
task :doc do
  libs = Dir.glob(File.join(ROOT_DIR, 'framework/lib', '*.swc'))
  system("#{get_executable('asdoc')} +configname=air -source-path framework/src -doc-sources framework/src -library-path+=#{libs.join(',')} -output doc/api")
end

namespace :test do  
  desc "Compile test application"
  task :build do
    project_path = File.join(ROOT_DIR, "tests/src", TEST_APP_NAME)
    target_project_path = File.join(ROOT_DIR, "tests/bin", TEST_APP_NAME.sub(/.mxml$/, '.swf'))
    source_path = [File.join(ROOT_DIR, "framework/src"), File.join(ROOT_DIR, "tests/src")]
    libs = Dir.glob(File.join(ROOT_DIR, 'tests/lib', '*.swc'))
    libs << Dir.glob(File.join(ROOT_DIR, 'framework/lib', '*.swc'))
    
    cmd = "#{get_executable('mxmlc')} +configname=air -library-path+=#{libs.join(',')} " << 
      "-output #{target_project_path} -debug=true -source-path=#{source_path.join(',')}" <<
      " #{project_path}"
    if !system(cmd)
      puts "failed to compile test application"
    end
  end
  
  desc "Run test application"
  task :run do
    project_path = File.join(ROOT_DIR, "tests/src", TEST_APP_NAME)
    target_project_air_descriptor = project_path.sub(/.mxml$/, '-app.xml')
    
    if !system("#{get_executable('adl')} #{target_project_air_descriptor} #{ROOT_DIR}")
      puts "failed to run test application"
    end
  end
end
