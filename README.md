# Ruby + MMTk

This repository provides builds of the [Ruby](https://www.ruby-lang.org/)
programming language, with [MMTk](https://www.mmtk.io/) as a garbage collector.
To download a build, find a recent nightly release at
https://github.com/chrisseaton/ruby-mmtk-builder/releases/tag/nightly
and download either the debug or release artefact.

Use `ruby --mmtk` to enable. See `ruby --help` for more information.

## Use as a development environment

`./build.sh` will set up a working full-source checkout and build of Ruby with
MMTk.

`WITH_LATEST_MMTK_CORE=yes` to use latest MMTk (may not work.)

`WITH_UPSTREAM_RUBY=yes` to merge with upstream Ruby (may not work.)

`WITH_DEBUG=yes` to build a debug version.

`TAG=mytag ./package.sh` then builds a tarball.
