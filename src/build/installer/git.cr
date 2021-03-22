require "file_utils"

require "../installer"
require "../shards_builder"
require "../source"

require "crest"

module Build::Installer
  class Git < Build::Installer::Base
    def initialize(source : Build::GitSource, options : Hash(Symbol, String | Nil))
      @source = source
      @options = options
    end

    def install(crystal_version : String, install_shards : Bool = true) : Void
      puts "Starting installation from git: #{@source.repo_uri}" if verbose
      puts "Working directory: #{working_directory}" if verbose

      Dir.cd(working_directory)

      unless git_installed?
        STDERR.puts "Unable to find git executable."
        exit 1
      end

      system("git clone #{@source.repo_uri}#{" --quiet" unless verbose} crystal")

      unless $?.success?
        STDERR.puts "Clone failed."
        exit 1
      end

      Dir.cd("crystal")

      system("git checkout #{crystal_version}#{" --quiet" unless verbose}")

      unless $?.success?
        STDERR.puts "Failed to switch to Crystal version branch '#{crystal_version}'."
        exit 1
      end

      system("make")

      unless $?.success?
        STDERR.puts "Make failed."
        exit 1
      end
    end

    private def working_directory : Path
      @working_directory ||= begin
        path = File.join(Dir.tempdir, "crystal-build-#{Random::Secure.hex(3)}")

        Dir.mkdir_p(path)

        Path[path]
      end
    end

    private def verbose : Bool
      !@options[:verbose].nil?
    end

    private def git_installed? : Bool
      `command -v git`

      $?.success?
    end
  end
end
