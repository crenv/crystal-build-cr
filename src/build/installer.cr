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

      target_file_path = prepare_file_download(install_directory.to_s, url)

      # Extract the downloaded tar file, giving us the name of the top-level
      # directory that Crystal was extracted to
      system("tar xf #{target_file_path} -C #{File.dirname(target_file_path)}")

      root_directory = @source.root_path(crystal_version)

      # Rename the root directory to just be the version number
      move_from = File.expand_path(File.join(File.dirname(target_file_path), root_directory))
      move_to = File.expand_path(File.join(File.dirname(target_file_path), crystal_version))
      system("mv #{move_from} #{move_to}")

      # Remove the tar file now that we're done with it
      FileUtils.rm(target_file_path)
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
