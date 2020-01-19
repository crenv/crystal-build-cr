require "json"
require "option_parser"

require "./build/version"

module Build
  def self.parse_options
    options = {} of Symbol => String

    OptionParser.parse do |parser|
      parser.banner = "build [options]"

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
    puts "Available Crystal versions:"

    text = File.read("src/releases.json")
    versions = JSON.parse(text).as_a.map { |release| release.as_h["tag_name"] }

    versions.each { |v| puts "  #{v}" }
  end
end

Build.parse_options
