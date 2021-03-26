module Build
  abstract class Source
    # The user-facing name of the source.
    abstract def name : String
  end
end
