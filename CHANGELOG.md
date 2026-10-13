## 0.2.0

* Update the example to socks_socket 2.0.0 and await Tor shutdown.

* Bump arti to 2.7.0 and its supporting crates to 0.47.0; needs Rust 1.92.
* Pin a reviewed `saturating-time` 0.5.0 fork with regression coverage for
  coarse platform clocks.
* Fix `tor_client_bootstrap` and `tor_client_set_dormant` freeing the client
  handle Dart still holds. Add `tor_client_free`; `Tor.stop` now releases the
  client handle.
* Bind the SOCKS listeners before `tor_start` returns, so a port collision
  fails `Tor.start` instead of leaving a dead proxy behind a published port.
* `Tor.stop` resets the wrapper's state, so Tor can be started again.
* `Tor.start` and `Tor.stop` run one at a time. A `stop` issued while a
  `start` is in progress waits for it and then tears it down.
* Concurrent `Tor.start` calls share one attempt and complete only when Tor is
  ready, or fail together with the same error.
* Release the native client and proxy when bootstrap fails during
  `Tor.start`, instead of leaving the proxy running.
* `Tor.disable` now stops the proxy like `Tor.stop`; before, it only changed
  the reported status while traffic kept flowing. It returns a `Future`.
* Fix SOCKS port selection giving up after one failed bind and sometimes
  picking port 0 or a privileged port. It now retries up to 32 ports in
  1024–65535.
* Free the state and cache directory strings passed to `tor_start`.
* Add `tor_string_free` and use it to release Rust error messages after
  Dart copies them.
* Strip NUL bytes from Rust error messages instead of panicking across FFI.
* `Tor.stop` now shuts down the client's runtime, releasing its threads and
  its state and cache files, and completes once they are released. Before,
  every start leaked a client that kept the cache open, so the data
  directory could not be deleted on Windows.
* Skip hidden files such as `.DS_Store` in the native source fingerprint and
  hash sources as bytes, so stray files no longer fail or invalidate builds.

## 0.1.0

* Build the Rust core with Flutter native assets instead of cargokit.
  Requires Flutter 3.47.2 or later, `rustup` on the build machine, and
  NDK 27 or later for Android.
* Remove `NotSupportedPlatform`; `Tor.throwRustException` no longer takes
  a bindings argument.
* Fix `Tor.start` never detecting a failed `tor_start`.

## 0.0.1

* TODO: Describe initial release.
