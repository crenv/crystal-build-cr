require "file_utils"

require "./source"

require "crest"

module Build
  class Installer
    def initialize(source : Build::Source, platform : String, arch : String)
      @source = source
      @platform = platform
      @arch = arch
    end

    # Install a specific *crystal_version* to an *install_directory*.
    def install(crystal_version : String, install_directory : Path)
      url = @source.url_for(crystal_version, @platform, @arch)
      puts "Downloading from #{@source.name} with URL: #{url}"

      tarball_path = prepare_file_download(url)
      # Extract Crystal to a subdirectory of the main temp directory
      target_subdirectory = File.join(File.dirname(tarball_path), "crystal-build-" + Random::Secure.hex(3))
      FileUtils.mkdir_p(target_subdirectory)

      # TODO: Should probably utilize some sort of checksum comparison here
      `tar xf '#{tarball_path}' -C '#{target_subdirectory}'`

      unless $?.success?
        puts "There was an issue extracting the downloaded tarball."
        exit 1
      end

      unless (root_dir = Dir.entries(target_subdirectory).find { |dir| dir =~ /crystal/ })
        STDERR.puts "Extracted tarball but could not determine the directory containing Crystal."
        exit 1
      end

      source = File.expand_path(File.join(target_subdirectory, root_dir))
      crystal_dir = File.expand_path(File.join(Installer.install_root, crystal_version))
      system("mv #{source} #{crystal_dir}")

      # Rename the root directory to just be the version number
      move_from = File.expand_path(File.join(File.dirname(target_file_path), root_directory))
      move_to = File.expand_path(File.join(File.dirname(target_file_path), crystal_version))
      system("mv #{move_from} #{move_to}")

    # Get the crenv versions directory path.
    def self.install_root : String
      root = ENV["CRENV_ROOT"]?

      if root.nil?
        STDERR.puts "CRENV_ROOT is not set."
        exit 1
      end

      File.join(root, "versions")
    end

    # Given the *url* for the tarball to be downloaded and the directory in
    # which to install Crystal, do some preparation for the downloading
    # process, and return the path to the downloaded tarball.
    private def prepare_file_download(url : String) : String
      filename = url.split("/").last
      tarball_path = File.join(Dir.tempdir, filename)

      # Check if the target file location is writable
      if !File.writable?(File.dirname(tarball_path))
        puts "Target not writable: #{File.dirname(tarball_path)}"
        exit 1
      end

      # Check if we've already downloaded the file
      # TODO: Should probably utilize some sort of checksum comparison here
      if File.exists?(tarball_path)
        STDERR.puts "Target file exists, skipping download."
      else
        Crest.get(url) { |resp| File.write(tarball_path, resp.body_io) }
      end

      tarball_path
    end
  end
end
