#!/usr/bin/env bash

set -euxo pipefail

wget https://raw.githubusercontent.com/mmtk/mmtk-core/master/rust-toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
/bin/sh -c ". ~/.cargo/env"
sudo export RUSTUP_TOOLCHAIN=$(cat rust-toolchain) && /root/.cargo/bin/rustup toolchain install $RUSTUP_TOOLCHAIN
sudo export RUSTUP_TOOLCHAIN=$(cat rust-toolchain) && /root/.cargo/bin/rustup target add i686-unknown-linux-gnu --toolchain $RUSTUP_TOOLCHAIN
PATH="/root/.cargo/bin:${PATH}"

if [ -v WITH_LATEST_MMTK_CORE ]
then
  git clone https://github.com/mmtk/mmtk-core
  pushd mmtk-core
else
  git clone https://github.com/wks/mmtk-core
  pushd mmtk-core
  git checkout is_arbitrary_address_alloced
fi
cargo build
popd

git clone https://github.com/mmtk/mmtk-ruby
pushd mmtk-ruby/mmtk
sed -i 's/^mmtk =/#mmtk =/g' Cargo.toml
cat ../../Cargo.toml.part >> Cargo.toml
cargo build
popd

git clone https://github.com/mmtk/ruby
pushd ruby
if [ -v WITH_UPSTREAM_RUBY ]
then
  git config --global user.email builder@example.com
  git config --global user.name Builder
  git remote add upstream git://github.com/ruby/ruby
  git fetch upstream
  git merge upstream/master
fi
cp ../mmtk-ruby/mmtk/target/debug/libmmtk_ruby.so ./
sudo apt-get install -y autoconf bison
./autogen.sh
./configure cppflags='-DUSE_THIRD_PARTY_HEAP -DUSE_TRANSIENT_HEAP=0' optflags='-O0' --prefix=$PWD/build --disable-install-doc
export LD_LIBRARY_PATH=$PWD
export MMTK_PLAN=NoGC
export THIRD_PARTY_HEAP_LIMIT=1000000000
make miniruby -j
./miniruby -e 'puts "Hello world!"'
popd
