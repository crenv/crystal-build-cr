require "file_utils"
require "semantic_version"

module Build
  class ShardsBuilder
    # Map all crystal versions to an applicable version of shards to be
    # installed alongside it.
    VERSION_MAP = {
      "1.0.0"  => "0.14.1",
      "0.36.1" => "0.14.1",
      "0.36.0" => "0.14.1",
      "0.35.1" => "0.14.1",
      "0.35.0" => "0.14.1",
      "0.34.0" => "0.11.1",
      "0.33.0" => "0.9.0",
      "0.32.1" => "0.9.0",
      "0.32.0" => "0.9.0",
      "0.31.1" => "0.9.0",
      "0.31.0" => "0.9.0",
      "0.30.1" => "0.9.0",
      "0.30.0" => "0.9.0",
      "0.29.0" => "0.9.0",
      "0.28.0" => "0.9.0",
      "0.27.2" => "0.9.0",
      "0.27.1" => "0.9.0",
      "0.27.0" => "0.9.0",
      "0.26.1" => "0.9.0",
      "0.26.0" => "0.9.0",
      "0.25.1" => "0.9.0",
      "0.25.0" => "0.9.0",
      "0.24.2" => "0.7.2",
      "0.24.1" => "0.7.2",
      "0.24.0" => "0.7.2",
      "0.23.1" => "0.7.1",
      "0.23.0" => "0.7.1",
      "0.22.0" => "0.7.1",
      "0.21.1" => "0.7.1",
      "0.21.0" => "0.7.1",
      "0.20.5" => "0.7.1",
      "0.20.4" => "0.7.1",
      "0.20.3" => "0.7.1",
      "0.20.1" => "0.7.1",
      "0.20.0" => "0.7.1",
      "0.19.4" => "0.7.1",
      "0.19.3" => "0.7.1",
      "0.19.2" => "0.7.1",
      "0.19.1" => "0.7.1",
      "0.19.0" => "0.7.1",
      "0.18.7" => "0.6.3",
      "0.18.6" => "0.6.3",
      "0.18.4" => "0.6.3",
      "0.18.2" => "0.6.3",
      "0.18.0" => "0.6.3",
      "0.17.4" => "0.6.3",
      "0.17.3" => "0.6.3",
      "0.17.2" => "0.6.3",
      "0.17.1" => "0.6.3",
      "0.17.0" => "0.6.3",
      "0.16.0" => "0.6.3",
      "0.15.0" => "0.6.2",
      "0.14.2" => "0.6.2",
      "0.14.1" => "0.6.2",
      "0.14.0" => "0.6.2",
      "0.13.0" => "0.6.2",
      "0.12.0" => "0.6.2",
      "0.11.1" => "0.6.0",
      "0.11.0" => "0.6.0",
      "0.10.2" => "0.6.0",
      "0.10.1" => "0.6.0",
      "0.10.0" => "0.6.0",
      "0.9.1"  => "0.5.3",
      "0.9.0"  => "0.5.3",
    }.map { |crystal_version, shards_version|
      [
        SemanticVersion.parse(crystal_version),
        SemanticVersion.parse(shards_version),
      ]
    }.to_h

    # Builds Shards using Crystal, saving the resulting binary to the provided
    # path. The provided path should include the binary name. Returns a boolean
    # representing the success or failure of the build process.
    def self.build(crystal_version : String, crystal_binary : String, target_binary_path : String, options : Hash(Symbol, String | Nil)) : Bool
      unless has_git?
        STDERR.puts "Unable to find git executable, which is required to install Shards."
        return false
      end

      # Change to a new temporary directory, saving our old spot
      original_working_dir = Dir.current
      build_directory = File.join(Dir.tempdir, "crystal-build-" + Random::Secure.hex(3))
      FileUtils.mkdir_p(build_directory)
      Dir.cd(build_directory)

      # Clone the repo and build
      system("git clone #{git_url}#{" --quiet" unless options[:verbose]}")

      unless $?.success?
        STDERR.puts "Clone failed."
        return false
      end

      # CD into the newly cloned repository
      Dir.cd("shards")

      # Switch to the appropriate version branch based on the version of Shards
      # we want to install

      if (shards_version = shards_version_by_crystal(crystal_version)).empty?
        return false
      end

      system("git checkout v#{shards_version}#{" --quiet" unless options[:verbose]}")

      unless $?.success?
        STDERR.puts "Failed to switch to Shards version branch 'v#{shards_version}'."
        return false
      end

      # Compile and build Shards - the make syntax changes over time so we need
      # to pick the right one
      shards_semantic_version = SemanticVersion.parse(shards_version)
      make_command = if shards_semantic_version >= SemanticVersion.parse("0.12.0")
                       "make CRYSTAL=#{crystal_binary} release=1 #{" > /dev/null" unless options[:verbose]}"
                     elsif shards_semantic_version >= SemanticVersion.parse("0.11.0")
                       "make CRYSTAL=\"#{crystal_binary} --release\"#{" > /dev/null" unless options[:verbose]}"
                     else
                       "make CRYSTAL=#{crystal_binary} CRFLAGS=--release#{" > /dev/null" unless options[:verbose]}"
                     end

      puts make_command if options[:verbose]
      system(make_command)

      return false unless $?.success?

      FileUtils.cp("bin/shards", target_binary_path)

      true
    end

    private def self.shards_version_by_crystal(crystal_version_string : String) : String
      looking_for = SemanticVersion.parse(crystal_version_string)

      sorted_known_versions = VERSION_MAP.keys.sort
      earliest_known_crystal = sorted_known_versions.first
      latest_known_crystal = sorted_known_versions.last

      shards_version = nil

      # Check if we even know what Crystal version we're looking for
      if sorted_known_versions.includes?(looking_for)
        return VERSION_MAP[looking_for].to_s.not_nil!
      else
        if looking_for > latest_known_crystal
          # We're trying to find Shards based on a version of Crystal which is
          # newer than the most recent Crystal this program is aware of, so
          # just use the same Shards version of the latest known Crystal.
          STDERR.puts <<-WARNING_MSG
            WARNING: Tried to determine Shards version for Crystal
            #{looking_for}, but the latest we know of is
            #{latest_known_crystal}. Trying the latest Shards version, but it
            might not work.
          WARNING_MSG

          return VERSION_MAP[latest_known_crystal].to_s.not_nil!
        elsif looking_for < earliest_known_crystal
          # We're trying to find Shards based on a version of Crystal which is
          # older than the oldest version of Crystal that we support.
          STDERR.puts <<-WARNING_MSG
            ERROR: Cannot build Shards for a version of Crystal older than
            #{earliest_known_crystal}. You asked for Crystal #{looking_for}.
          WARNING_MSG

          return ""
        else
          return ""
        end
      end
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
