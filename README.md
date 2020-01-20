A rewrite of crystal-build in Crystal.

TODO: Write an actual README

### Other Notes

Prepackaged Crystal distributions work fine, but because they aren't built from scratch on the local machine, you might run into library issues on macOS, like for SSL libraries. I solved the SSL library issue with:

```bash
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:"/usr/local/opt/openssl/lib/pkgconfig"
```
