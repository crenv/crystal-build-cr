require "./source"

require "uri"

module Build
  class GitSource < Build::Source
    getter :repo_uri

    def initialize(repo_uri : URI)
      @repo_uri = repo_uri
    end

    def name : String
      "Git"
    end
  end
end
