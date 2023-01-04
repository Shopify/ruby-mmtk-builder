# Ruby + MMTk

This repository provides builds of the [Ruby](https://www.ruby-lang.org/)
programming language, with [MMTk](https://www.mmtk.io/) as a garbage collector.
To download a build, find a recent nightly release at
https://github.com/Shopify/ruby-mmtk-builder/releases/tag/nightly
and download either the debug or release artefact.

Use `ruby --mmtk` to enable. See `ruby --help` for more information.

## Use as a development environment

`./build.sh` will set up a working full-source checkout and build of Ruby with
MMTk. MMTk is Linux only.

### MacOS local development

A Containerfile is included that will run `build.sh` and create an
image with the resulting Ruby build.

Make sure you have installed `podman` and then run

```
podman build .
```

Within this directory.

## Valid Build options

The following environment variables can be used

`WITH_LATEST_MMTK_CORE=1` to use latest MMTk (may not work.)

`WITH_UPSTREAM_RUBY=yes` to merge with upstream Ruby (may not work.)

`WITH_DEBUG=yes` to build a debug version.

## Building a Ruby release

First build using `./build.sh`. Then `TAG=mytag ./package.sh` to build a tarball.
