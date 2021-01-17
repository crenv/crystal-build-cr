require "json"
require "uri"
require "option_parser"

require "./build/github"
require "./build/installer/git"
require "./build/installer/tarball"
require "./build/source/git_source"
require "./build/source/github_source"
require "./build/version"

module Build
  @@options = {} of Symbol => String

  def self.parse_options
    options = Hash(Symbol, String | Nil).new(default_value: nil)

    OptionParser.parse do |parser|
      parser.banner = "crenv install [options] <version>"

      parser.on("--version", "Print the version number") do
        puts Build::VERSION
        exit
      end

      parser.on("-h", "--help", "Print this help") do
        puts parser
        exit
      end

      parser.on("-v", "--verbose", "Enable verbose output") do
        options[:verbose] = "true"
      end

      parser.on("-l", "--list", "Print a list of installable Crystal versions") do
        print_crystal_versions_list
        exit
      end

      parser.on("-s", "--from-source", "Build and install from source") do
        options[:from_source] = "true"
      end

      parser.on("--repo-url URL", "The git repository to fetch sources from") do |repo_url|
        options[:source_repo_url] = repo_url
      end
    end

    options
  end

  def self.print_crystal_versions_list
    Build::Github.new("crystal-lang/crystal").versions.each { |v| puts v }
  end
end

options = Build.parse_options

version = if ARGV[0]?
            ARGV[0]
          else
            if File.exists?(".crystal-version")
              File.read(".crystal-version").strip
            else
              puts "No version provided."
              exit 1
            end
          end

uname = `uname`.downcase.strip
platform = if uname == "darwin"
             "darwin"
           elsif uname == "linux"
             "linux"
           else
             STDERR.puts "Unable to determine your operating system, defaulting to 'linux'."
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

if options[:from_source]
  repo_url = options[:source_repo_url] || "https://github.com/crystal-lang/crystal.git"

  unless repo_url.ends_with?(".git")
    STDERR.puts "Invalid git repository URL: #{repo_url}"
    exit 1
  end

  repo_url = begin
    URI.parse(repo_url)
  rescue e : URI::Error
    STDERR.puts "Unable to parse provided git repository URL: #{repo_url}"
    STDERR.puts e.message
    exit 1
  end

  source = Build::GitSource.new(repo_url)
  installer = Build::Installer::Git.new(source, options)

  installer.install(version)
else
  repo = ENV.fetch("CRYSTAL_BUILD_GITHUB_REPO", "crystal-lang/crystal")
    .downcase
    .sub(/^https?:\/\/github\.com\//, "")

  source = Build::GithubSource.new(repo)
  installer = Build::Installer::Tarball.new(source, platform, arch, options)

  installer.install(version)
end
