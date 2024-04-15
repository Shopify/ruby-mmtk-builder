#!/usr/bin/env bash

set -euxo pipefail

build_root=$(pwd)
mmtk_core_location=$build_root/mmtk-core
mmtk_ruby_location=$build_root/mmtk-ruby
ruby_src_location=$build_root/ruby

enable_debug=${WITH_DEBUG:-0}
default_rust_toolchain=${RUSTUP_TOOLCHAIN:-stable}
ruby_merge_upstream=${WITH_UPSTREAM_RUBY:-0}
mmtk_core_use_latest=${WITH_LATEST_MMTK_CORE:-0}
mmtk_core_use_local=1

is_darwin=0
[[ "Darwin" = `uname` ]] &&
    is_darwin=1

function install_rust {
    [[ $# -lt 1 ]] && exit 1

    if [[ ! -d $HOME/.cargo ]]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
        source $HOME/.cargo/env
    fi
    rustup toolchain install $1
}

function setup_mmtk_core {
    [[ $# -lt 2 ]] && exit 1

    git clone --depth=1 https://github.com/mmtk/mmtk-core $1

    if [[ $2 -gt 0 ]]; then
        pushd $1
        # TODO: Find out what the status of this branch is
        git remote add wks https://github.com/wks/mmtk-core &&
            git fetch wks &&
            git checkout wks/ruby-friendly-tracing
        popd
    fi
}

function setup_mmtk_ruby {
    [[ $# -lt 1 ]] && exit

    git clone --depth=1 https://github.com/mmtk/mmtk-ruby $1
}

function build_mmtk_ruby {
    [[ $# -lt 3 ]] && exit 1

    pushd $1/mmtk

    if [[ $2 -gt 0 ]]; then
        backup_ext=""
        [[ 1 -eq $is_darwin ]] &&
           backup_ext="\'\'"

        sed -i $backup_ext 's/^git =/#git =/g' Cargo.toml
        sed -i $backup_ext 's/^rev =/#rev =/g' Cargo.toml
        sed -i $backup_ext 's/^#path =/path =/g' Cargo.toml
    fi

    if [[ $3 -gt 0 ]]; then
        cargo build
    else
        cargo build --release
    fi
    popd
}

function setup_ruby {
    [[ $# -lt 2 ]] && exit 1

    if [[ -d $1 ]]; then
       pushd $1 && git pull
    else
        git clone --depth=1 https://github.com/mmtk/ruby $1
    fi

    pushd $1
    if [[ $2 -gt 0 ]]; then
        git config --global user.email builder@example.com
        git config --global user.name Builder
        git remote add upstream https://github.com/ruby/ruby &&
            git fetch upstream &&
            git merge --no-edit upstream/master
    fi
    popd
}

function build_ruby {
    [[ $# -lt 3 ]] && exit 1

    sudo apt-get install -y autoconf bison libyaml-dev
    pushd $1

    ./autogen.sh

    if [[ $3 -gt 0 ]]; then
        CONFIGURE_FLAGS='cppflags=-DRUBY_DEBUG --with-mmtk-ruby-debug'
    else
        CONFIGURE_FLAGS=
    fi

    ./configure --disable-install-doc --with-mmtk-ruby=$2 --prefix=$1/build $CONFIGURE_FLAGS &&
        make &&
        make install
    popd
}


[[ ! `command -v rustc` ]] &&
    install_rust $default_rust_toolchain

[[ ! -d $mmtk_core_location ]] &&
    setup_mmtk_core $mmtk_core_location $mmtk_core_use_latest
[[ ! -d $mmtk_ruby_location ]] &&
    setup_mmtk_ruby $mmtk_ruby_location

build_mmtk_ruby $mmtk_ruby_location $mmtk_core_use_local $enable_debug
setup_ruby $ruby_src_location $ruby_merge_upstream
build_ruby $ruby_src_location $mmtk_ruby_location $enable_debug

cd $build_root
./ruby/build/bin/ruby --mmtk -v
