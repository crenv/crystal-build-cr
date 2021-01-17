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
      puts "Not implemented."
    end
  end
end
