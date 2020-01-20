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
      parser.banner = "build [options]"

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

version = ARGV[0]

Build::Installer.new(
  source: Build::GithubSource.new,
  platform: "darwin",
  arch: "x64"
).install(ARGV[0], install_path)
