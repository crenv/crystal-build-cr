require "file_utils"

require "./installer"
require "../shards_builder"
require "../source"

require "crest"

module Build::Installer
  class Tarball < Build::Installer::Base
    def initialize(
      source : Build::TarballSource,
      platform : String,
      arch : String,
      options : Hash(Symbol, String | Nil)
    )
      @source = source
      @platform = platform
      @arch = arch
      @options = options
    end

    def install(crystal_version : String, install_shards : Bool = true) : Void
      url = @source.url_for(crystal_version, @platform, @arch)
      puts "Downloading from #{@source.name} with URL: #{url}" if @options[:verbose]

      tarball_path = prepare_file_download(url)
      # Extract Crystal to a subdirectory of the main temp directory
      target_subdirectory = File.join(File.dirname(tarball_path), "crystal-build-" + Random::Secure.hex(3))
      FileUtils.mkdir_p(target_subdirectory)

      # TODO: Should probably utilize some sort of checksum comparison here
      `tar xf '#{tarball_path}' -C '#{target_subdirectory}'`

      unless $?.success?
        STDERR.puts "There was an issue extracting the downloaded tarball."
        exit 1
      end

      unless (root_dir = Dir.entries(target_subdirectory).find { |dir| dir =~ /crystal/ })
        STDERR.puts "Extracted tarball but could not determine the directory containing Crystal."
        exit 1
      end

      unless (install_root = Installer::Base.install_root)
        STDERR.puts "Unable to determine install root. Is CRENV_ROOT set?"
        exit 1
      end

      FileUtils.mkdir_p(install_root)
      source = File.expand_path(File.join(target_subdirectory, root_dir))
      crystal_dir = File.expand_path(File.join(install_root, crystal_version))
      system("mv #{source} #{crystal_dir}")

      # Install Shards if necessary
      if install_shards
        target_shards_path = File.join(crystal_dir, "bin", "shards")
        if File.exists?(target_shards_path)
          puts "Found existing shards binary, skipping shards build & install." if @options[:verbose]
        else
          crystal_binary = File.join(crystal_dir, "bin", "crystal")

          if !ShardsBuilder.build(crystal_version, crystal_binary, target_shards_path, @options)
            STDERR.puts "Shards installation failed."
            exit 1
          end
        end
      end

      puts "Crystal #{crystal_version} installed successfully."
    end

    # Given the *url* for the tarball to be downloaded and the directory in
    # which to install Crystal, do some preparation for the downloading
    # process, and return the path to the downloaded tarball.
    private def prepare_file_download(url : String) : String
      filename = url.split("/").last
      tarball_path = File.join(Dir.tempdir, filename)

      # Check if the target file location is writable
      if !File.writable?(File.dirname(tarball_path))
        STDERR.puts "Target not writable: #{File.dirname(tarball_path)}"
        exit 1
      end

      # Check if we've already downloaded the file
      # TODO: Should probably utilize some sort of checksum comparison here
      if File.exists?(tarball_path)
        puts "Target file exists, skipping download." if @options[:verbose]
      else
        Crest.get(url) { |resp| File.write(tarball_path, resp.body_io) }
      end

      tarball_path
    end
  end
end
