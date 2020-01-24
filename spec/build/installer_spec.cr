require "../spec_helper"

require "../../src/build/installer"
require "../../src/build/source/github_source"
require "../support/test_source"

require "file_utils"
require "http"

Mocks.create_mock ::HTTP::Client do
  mock self.get(url)
end

describe Build::Installer do
  it "initializes" do
    installer = Build::Installer.new(
      source: Build::GithubSource.new,
      platform: "darwin",
      arch: "x64"
    )

    installer.should_not be_nil
  end

  it "installs" do
    tarball_path = "/Users/taylorthurlow/Code/crystal-build-cr/spec/fixtures/crystal-0.0.0.tar.gz"

    source = TestSource.new
    installer = Build::Installer.new(source, "darwin", "x64")

    allow(HTTP::Client).to receive(self.get("http://example.com/crystal-0.0.0.tar.gz")).and_return(nil)

    install_path = Path["tmp/crystals"]
    FileUtils.rm_rf(install_path.to_s)

    move_from = File.join([Dir.current, "spec/fixtures/crystal-0.0.0.tar.gz"])
    move_to = File.join([install_path, "crystal-0.0.0.tar.gz"])
    FileUtils.mkdir_p(File.dirname(move_to))
    FileUtils.cp(move_from, move_to)

    installer.install("0.0.0", install_path)

    binstub_path = File.join([install_path, "0.0.0/bin/crystal"])
    result = `./tmp/crystals/0.0.0/bin/crystal`.strip
    result.should eq "success"

    FileUtils.rm_rf(install_path.to_s)
  end
end
