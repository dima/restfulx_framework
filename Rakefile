# how to update the gh-pages docs branch automatically
# 1. rake docs in master branch and commit
# 2. checkout gh-pages
# 3. git read-tree --prefix=master/ -u master
# 4. cp -r master/docs/api/* .
# 5. rm -rf master
# 6. git commit
# 7. git checkout master

FRAMEWORK_VERSION = "1.2.4"

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
  system("#{get_executable('compc')} +configname=air -keep-as3-metadata+=Resource,HasOne,HasMany,BelongsTo,DateTime,Lazy,Ignored,Nested -load-config+=framework/restfulx-config.xml -library-path+=#{libs.join(',')}")
end

desc "Compile and run test application"
task :test => ["test:build", "test:run"]

desc "Build API documentation"
task :doc do
  libs = Dir.glob(File.join(ROOT_DIR, 'framework/lib', '*.swc'))
  packages = {
    "org.restfulx" => "Provides central access to a number of frequently used subsystems, configuration options and helpers.",
    "org.restfulx.collections" => "ArrayCollection extensions that help dealing with RxModels.",
    "org.restfulx.commands" => "Command pattern specific classes.",
    "org.restfulx.components.rx" => "Reusable MXML components that maybe used by the RestfulX code generation engine.",
    "org.restfulx.controllers" => "Various framework controllers such as RXApplicationController and ModelsController.",
    "org.restfulx.controllers.mock" => "Adds a few testing specific controllers.",
    "org.restfulx.events" => "Events dispatched by the framework.",
    "org.restfulx.models" => "Classes used by RX models.",
    "org.restfulx.serializers" => "Serializers provided by the framework, including XML, ValueObject and JSON.",
    "org.restfulx.services" => "Services provided by the framework including XML-over-HTTP, JSON-over-HTTP, CouchDB and AIR.",
    "org.restfulx.services.air" => "Adobe AIR service provider classes.",
    "org.restfulx.services.as3http" => "Direct CouchDB, XML and JSON service providers based on the as3httpclientlib.",
    "org.restfulx.services.http" => "XML and JSON service providers based on the default Flex HTTPService.",
    "org.restfulx.services.mock" => "Adds a few testing specific service providers.",
    "org.restfulx.utils" => "Framework utilties.",
    "org.restfulx.validators" => "Validation classes for proxying server-side/service provider errors to the UI."
  }
  
  package_list = packages.keys.map do |key|
    "-package #{key} \"#{packages[key].gsub(/\s/, "\\ ")}\""
  end
    
  system("#{get_executable('asdoc')} +configname=air -source-path framework/src -doc-sources framework/src -library-path+=#{libs.join(',')} #{package_list.join(" ")} -output doc/api  -main-title '\"RestfulX\ Framework\ #{FRAMEWORK_VERSION}\ API\ Documenation\"'")
end

desc "Build a framework release"
task :release => ["build", "doc"] do
  FileUtils.mkdir_p("tmp/restfulx-#{FRAMEWORK_VERSION}/docs")
  FileUtils.cp("framework/bin/restfulx.swc", "tmp/restfulx-#{FRAMEWORK_VERSION}/restfulx-#{FRAMEWORK_VERSION}.swc")
  FileUtils.cp_r("doc/api", "tmp/restfulx-#{FRAMEWORK_VERSION}/docs")
  FileUtils.cp_r("framework/src", "tmp/restfulx-#{FRAMEWORK_VERSION}")
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
