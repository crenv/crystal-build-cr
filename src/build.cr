require "json"
require "option_parser"

require "./build/github"
require "./build/installer"
require "./build/source"
require "./build/source/github_source"
require "./build/version"

module Build
  def self.parse_options
    options = {} of Symbol => String

    OptionParser.parse do |parser|
      parser.banner = "crenv install [options] <version>"

      parser.on("-h", "--help", "Print this help") do
        puts parser
        exit
      end

      parser.on("-v", "--version", "Print the version number") do
        puts Build::VERSION
        exit
      end

      parser.on("-l", "--list", "Print a list of installable Crystal versions") do
        print_crystal_versions_list
        exit
      end
    end

    options
  end

  def self.print_crystal_versions_list
    Build::Github.new("crystal-lang/crystal").versions.each { |v| puts v }
  end
end

options = Build.parse_options

# Determine installation path using CRENV environment variable
install_path = if ENV["CRENV_ROOT"]?
                 path_string = File.join(ENV["CRENV_ROOT"], "versions")
                 Path[path_string]
               else
                 puts "Expected to find crenv root in $CRENV_ROOT."
                 exit 1
               end

version = if ARGV[0]?
            ARGV[0]
          else
            puts "No version provided."
            exit 1
          end

uname = `uname`.downcase.strip
platform = if uname == "darwin"
             "darwin"
           elsif uname == "linux"
             "linux"
           else
             puts "Warning: Unable to determine your operating system, defaulting to 'linux'."
             "linux"
           end

long_size = `getconf LONG_BIT`.strip.to_i8?
arch = if long_size == 64
         "x64"
       elsif long_size == 32
         "x86"
       else
         "x64"
       end

Build::Installer.new(
  source: Build::GithubSource.new,
  platform: platform,
  arch: arch
).install(ARGV[0], install_path)
