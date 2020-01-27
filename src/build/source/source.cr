require "uri"

module Build
  abstract class Source
    # Get a URI for downloading a Crystal tarball with a given
    # *crystal_version*.
    abstract def url_for(
      crystal_version : String,
      platform : String,
      arch : String
    ) : String

    # Get the path to the main Crystal directory given the downloaded tarball
    # structure.
    abstract def root_path(crystal_version : String) : String

    # The user-facing name of the source.
    abstract def name : String
  end
end
