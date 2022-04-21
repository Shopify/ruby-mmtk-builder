#!/usr/bin/env bash

set -euxo pipefail

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
source $HOME/.cargo/env

if [ -v WITH_LATEST_MMTK_CORE ]
then
  git clone --depth=1 https://github.com/mmtk/mmtk-core
else
  git clone --depth=1 https://github.com/mmtk/mmtk-core # https://github.com/wks/mmtk-core
  # Currently no difference
fi

# Building mmtk-core in the mmtk-core directory has no effect for mmtk-ruby.
# When building mmtk-ruby, it will build the source of mmtk-core, too,
# and the generated object files will be in mmtk-ruby/mmtk/target/

export RUSTUP_TOOLCHAIN=nightly # $(cat rust-toolchain)
rustup toolchain install $RUSTUP_TOOLCHAIN

git clone --depth=1 https://github.com/mmtk/mmtk-ruby
pushd mmtk-ruby/mmtk
sed -i 's/^mmtk =/#mmtk =/g' Cargo.toml
cat ../../Cargo.toml.part >> Cargo.toml
cargo +nightly build --release
popd

git clone --depth=1 https://github.com/mmtk/ruby
pushd ruby
if [ -v WITH_UPSTREAM_RUBY ]
then
  git config --global user.email builder@example.com
  git config --global user.name Builder
  git remote add upstream https://github.com/ruby/ruby
  git fetch upstream
  git merge upstream/master
fi
sudo apt-get install -y autoconf bison
./autogen.sh
./configure --with-mmtk-ruby=../mmtk-ruby --prefix=$PWD/build --disable-install-doc
export MMTK_PLAN=MarkSweep
export THIRD_PARTY_HEAP_LIMIT=500000000
make miniruby -j
export RUST_LOG=info
./miniruby -e 'puts "Hello world!"'
make install -j
popd
