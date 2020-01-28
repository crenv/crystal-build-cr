require "../spec_helper"

require "../../src/build/installer"
require "../support/test_source"

require "file_utils"

describe Build::Installer do
  it "initializes" do
    Build::Installer.new(
      source: TestSource.new,
      platform: "darwin",
      arch: "x64"
    ).should_not be_nil
  end

  it "installs" do
    tarball_path = "/Users/taylorthurlow/Code/crystal-build-cr/spec/fixtures/crystal-0.0.0.tar.gz"
    installer = Build::Installer.new(TestSource.new, "darwin", "x64")

    ENV["CRENV_ROOT"] = Path["tmp/crenv"].to_s
    install_path = File.join(ENV["CRENV_ROOT"], "versions")
    FileUtils.rm_rf(install_path.to_s)

    FileUtils.cp(
      File.join(Dir.current, "spec/fixtures/crystal-0.0.0.tar.gz"),
      Dir.tempdir
    )

    crystal_binary = File.join("tmp", "crenv", "versions", "0.0.0", "bin", "crystal")
    shards_binary_path = File.join("tmp", "crenv", "versions", "0.0.0", "bin", "shards")
    installer.install("0.0.0", install_shards: false)

    binstub_path = File.join(install_path.to_s, "0.0.0/bin/crystal")
    result = `./tmp/crenv/versions/0.0.0/bin/crystal`.strip
    result.should eq "success"
  ensure
    FileUtils.rm_rf(install_path.to_s)
  end
end
