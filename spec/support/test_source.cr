require "../../src/build/source"

class TestSource < Build::Source
  def initialize
  end

  def url_for(crystal_version : String, platform : String, arch : String) : String
    "http://example.com/crystal-0.0.0.tar.gz"
  end

  def name : String
    "Test"
  end
end
