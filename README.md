`./build.sh` will set up a working full-source checkout and build of Ruby with
MMTk.

`WITH_LATEST_MMTK_CORE=yes` to use latest MMTk (may not work.)

`WITH_UPSTREAM_RUBY=yes` to merge with upstream Ruby (may not work.)

`WITH_DEBUG=yes` to build a debug version.

`TAG=mytag ./package.sh` then builds a tarball.

If you download a build, remember to set the environment to configure it to
use it.

```
export MMTK_PLAN=MarkSweep
export THIRD_PARTY_HEAP_LIMIT=1000000000
```
