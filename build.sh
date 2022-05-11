#!/usr/bin/env bash

set -euxo pipefail

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
source $HOME/.cargo/env

if [ -v WITH_LATEST_MMTK_CORE ]
then
  git clone https://github.com/mmtk/mmtk-core
else
  git clone https://github.com/mmtk/mmtk-core # https://github.com/wks/mmtk-core
  # git checkout -b ...
fi

export RUSTUP_TOOLCHAIN=nightly # $(cat rust-toolchain)
rustup toolchain install $RUSTUP_TOOLCHAIN

git clone https://github.com/mmtk/mmtk-ruby
pushd mmtk-ruby/mmtk
sed -i 's/^mmtk =/#mmtk =/g' Cargo.toml
cat ../../Cargo.toml.part >> Cargo.toml
if [ -v WITH_DEBUG ]
then
  cargo +nightly build
else
  cargo +nightly build --release
fi
popd

git clone https://github.com/mmtk/ruby
pushd ruby
if [ -v WITH_UPSTREAM_RUBY ]
then
  git config --global user.email builder@example.com
  git config --global user.name Builder
  git remote add upstream https://github.com/ruby/ruby
  git fetch upstream
  git merge upstream/master
fi
sudo apt-get install -y autoconf bison libyaml-dev
./autogen.sh
if [ -v WITH_DEBUG ]
then
  ./configure cppflags=-DRUBY_DEBUG --with-mmtk-ruby=../mmtk-ruby --with-mmtk-ruby-debug --prefix=$PWD/build
else
  ./configure --with-mmtk-ruby=../mmtk-ruby --prefix=$PWD/build
fi
export MMTK_PLAN=MarkSweep
export THIRD_PARTY_HEAP_LIMIT=1000000000
make
make install
if [ -v WITH_DEBUG ]
then
  RELEASE_SUFFIX=debug
else
  RELEASE_SUFFIX=release
fi
RELEASE=ruby-mmtk-linux-amd64-`date +%Y%m%d%H%M%S`-$RELEASE_SUFFIX
cp -r build $RELEASE
tar -zcf ../$RELEASE.tar.gz $RELEASE
popd

tar -zxf $RELEASE.tar.gz
export PATH=$PWD/$RELEASE/bin:$PATH
export MMTK_PLAN=MarkSweep
export THIRD_PARTY_HEAP_LIMIT=1000000000
if [ -v WITH_DEBUG ]
then
  export RUST_LOG=info
fi

ruby --version

ruby -e "puts 'Hello, World!'"
