require "file_utils"

module Build
  class ShardsBuilder
    # Builds Shards using Crystal, saving the resulting binary to the provided
    # path. The provided path should include the binary name. Returns a boolean
    # representing the success or failure of the build process.
    def self.build(crystal_binary : String, target_binary_path : String) : Bool
      raise "Unable to find git executable." unless has_git?

      # Change to a new temporary directory, saving our old spot
      original_working_dir = Dir.current
      build_directory = File.join(Dir.tempdir, "crystal-build-" + Random::Secure.hex(3))
      FileUtils.mkdir_p(build_directory)
      Dir.cd(build_directory)

      # Clone the repo and build
      system("git clone #{git_url}")

      unless $?.success?
        STDERR.puts "Clone failed."
        exit 1
      end

      Dir.cd("shards")

      system("make CRYSTAL=#{crystal_binary} CRFLAGS=--release")

      unless $?.success?
        STDERR.puts "Shards build failed."
        exit 1
      end

      FileUtils.cp("bin/shards", target_binary_path)

      true
    end

    private def self.has_git? : Bool
      `command -v git`

      $?.success?
    end

    private def self.git_url : String
      "https://github.com/crystal-lang/shards.git"
    end
  end
end
