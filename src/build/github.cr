require "json"

require "crest"

module Build
  class Github
    def initialize(repo : String)
      @repo = repo
    end

    def fetch_release(version : String) : JSON::Any
      fetch_as_json("releases/tags/#{version}")
    end

    def fetch_releases : JSON::Any
      fetch_as_json("releases?per_page=100")
    end

    # Get a date sorted (most recent first) list of release tags
    def versions : Array(String)
      fetch_releases.as_a
        .sort_by { |r| r.as_h["published_at"].as_s }
        .reverse
        .map { |r| r["tag_name"].as_s }
    end

    private def fetch_as_json(path : String) : JSON::Any
      response = fetch(path)

      JSON.parse(response.body)
    end

    private def fetch(path : String) : Crest::Response
      request_url = repo_base_api_url + path

      Crest::Request.new(:get,
        request_url,
        headers: {"Accept" => "application/vnd.github.v3+json"},
      ).execute
    end

    private def repo_base_api_url : String
      "https://api.github.com/repos/#{@repo}/"
    end
  end
end
