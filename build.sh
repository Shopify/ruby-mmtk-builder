#!/usr/bin/env bash

set -euxo pipefail

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
source $HOME/.cargo/env

WITH_LATEST_MMTK_CORE=yes # always using latest at the moment

git clone https://github.com/mmtk/mmtk-core
pushd mmtk-core
if [ ! -v WITH_LATEST_MMTK_CORE ]
then
  git remote add wks https://github.com/wks/mmtk-core
  git checkout wks/ruby-friendly-tracing
fi
popd

export RUSTUP_TOOLCHAIN=stable # $(cat mmtk-core/rust-toolchain)
rustup toolchain install $RUSTUP_TOOLCHAIN

git clone https://github.com/mmtk/mmtk-ruby
pushd mmtk-ruby/mmtk
sed -i 's/^mmtk =/#mmtk =/g' Cargo.toml
cat ../../Cargo.toml.part >> Cargo.toml
if [ -v WITH_DEBUG ]
then
  cargo build
else
  cargo build --release
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
make
make install
popd

ruby/build/bin/ruby -v
