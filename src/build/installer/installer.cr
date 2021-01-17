module Build::Installer
  abstract class Base
    # Install a specific *crystal_version* to crenv.
    abstract def install(crystal_version : String, install_shards : Bool = true) : Void

    protected def self.install_root : String | Nil
      root = ENV["CRENV_ROOT"]?

      File.join(root, "versions") if root
    end
  end
end
