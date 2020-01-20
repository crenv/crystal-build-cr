module Build
  class GithubSource < Build::Source
    def initialize
      @github = Build::Github.new("crystal-lang/crystal")
    end

    def url_for(crystal_version : String, platform : String, arch : String) : String
      download_urls(crystal_version)["#{platform}_#{arch}"]
    end

    def name : String
      "GitHub"
    end

    private def asset_urls(crystal_version : String) : Array(String)
      data = @github.fetch_release(crystal_version).as_h
      data["assets"].as_a.map { |asset| asset.as_h["browser_download_url"].as_s }
    end

    private def download_urls(crystal_version : String) : Hash(String, String)
      download_urls = asset_urls(crystal_version)

      # Translate a hash of binary names/types using a regex that we can apply
      # to a list of download URLS. Entries which have no regex match will be
      # excluded from the final result.
      {
        linux_x64:   /linux.*64/,
        linux_x86:   /linux.*86/,
        darwin_x64:  /darwin/,
        freebsd_x64: /freebsd/,
      }.map { |name, regex|
        if (url = download_urls.find { |url| url =~ regex })
          [name.to_s, url.to_s]
        else
          nil
        end
      }.compact.to_h
    end
  end
end
