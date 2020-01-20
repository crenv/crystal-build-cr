require "crest"
require "file_utils"

module Build
  class Installer
    def initialize(source : Build::Source, platform : String, arch : String)
      @source = source
      @platform = platform
      @arch = arch
    end

    def install(crystal_version : String, install_directory : Path)
      url = @source.url_for(crystal_version, @platform, @arch)

      puts "Downloading from #{@source.name} with URL: #{url}"
      puts "Installing to path: #{install_directory}"

      # The name of the tar file we're about to download
      filename = url.split("/").last

      # The absolute path to save the tar file to
      target_file = File.join(install_directory.to_s, filename)

      # Create any directories necessary
      Dir.mkdir_p(File.dirname(target_file))

      # Check if the target file location is writable
      if !File.writable?(File.dirname(target_file))
        puts "Target not writable: #{File.dirname(target_file)}"
        exit 1
      end

      # Check if we've already downloaded the file
      # TODO: Should probably utilize some sort of checksum comparison here
      if File.exists?(target_file)
        puts "Target file exists, skipping download."
      else
        Crest.get(url) { |resp| File.write(target_file, resp.body_io) }
      end

      # Extract the downloaded tar file, giving us the name of the top-level
      # directory that Crystal was extracted to
      root_directory = extract_tar(target_file)

      # Rename the root directory to just be the version number
      move_from = File.expand_path(File.join(File.dirname(target_file), root_directory))
      move_to = File.expand_path(File.join(File.dirname(target_file), crystal_version))

      system("mv #{move_from} #{move_to}")

      # Remove the tar file now that we're done with it
      FileUtils.rm(target_file)
    end

    # Extract the tar file to the directory it is contained within, and return
    # the name of the top-level directory that is the main crystal directory we
    # just extracted.
    private def extract_tar(target_file : String) : String
      # Capture stderr - tar outputs all verbose logging to stderr, even if
      # there are no errors
      stderr = IO::Memory.new
      status = Process.run(
        "tar",
        args: ["xvf", target_file, "-C", File.dirname(target_file)],
        error: stderr
      )

      root_directories = root_directories_from_tar_output(stderr.to_s)

      select_crystal_root_directory(root_directories)
    end

    # Parse the output of a verbose "tar" run and use it to determine the
    # top-level root directory names that were created
    private def root_directories_from_tar_output(tar_output : String) : Array(String)
      tar_output.to_s
        .chomp
        .split('\n')
        .map { |l| l.split("/").first.tr("x ", "") }
        .uniq
    end

    # Of all top-level *directory_names* in a provided list, find the one that
    # is most likely the main Crystal directory. Currently distribution
    # tarballs only have one directory in them, but we do it this way to
    # hopefully avoid any breaks in the future, if the tarball structure
    # changes.
    private def select_crystal_root_directory(directory_names : Array(String)) : String
      # Look for "crystal" in the name, but fall back to the first directory if
      # we can't find that
      directory_names.find { |dn| dn =~ /crystal/ } || directory_names.first
    end
  end
end
