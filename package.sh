#!/usr/bin/env bash

set -euxo pipefail

if [ -v WITH_DEBUG ]
then
  RELEASE_SUFFIX=debug
else
  RELEASE_SUFFIX=release
fi
RELEASE=ruby-mmtk-linux-amd64-$TAG-$RELEASE_SUFFIX
pushd ruby
cp -r build $RELEASE
tar -zcf ../$RELEASE.tar.gz $RELEASE
popd

tar -zxf $RELEASE.tar.gz
$RELEASE/bin/ruby -v
