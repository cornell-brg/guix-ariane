#!/usr/bin/env bash
set -e
# Set max number of jobs
export NUM_JOBS=8

# Set install dir for tools
export INSTALL_DIR=${HOME}/.local
mkdir -p ${INSTALL_DIR}
export PATH=${INSTALL_DIR}:${PATH}

# Dependencies
## Python3
guix install python

## Verilator
### I used version 4.110 which is used in the ariane CI
### Version 4.014 does _not_ work despite being referenced in the arianne repo (parsing errors)
### Version 4.204 also does not seem to work (compiler errors)
export version=4.110
wget https://github.com/verilator/verilator/archive/refs/tags/v${version}.tar.gz
tar -xvf v${version}.tar.gz
rm v${version}.tar.gz
cd verilator-${version}
autoconf && ./configure --prefix=${INSTALL_DIR}
make -j${NUM_JOBS}
make install
cd ..

# Install device-tree-compiler. I used just used the latest release (v1.6.1)
#export version=1.6.1
#wget https://github.com/dgibson/dtc/archive/refs/tags/v${version}.tar.gz
#tar -xvf v${version}.tar.gz
#cd dtc-${version}
#make -j${NUM_JOBS} install DESTDIR=${INSTALL_DIR}
guix install dtc

# Install RISCV tools
## Set install folder
export RISCV=${HOME}/riscv
export PATH=${RISCV}/bin:${PATH}
mkdir -p ${RISCV}

# The install scripts use precompiled libs from sifive, but they at least work on our machine
# In theory they could be built from source or grabbed from a package manager
RISCV64_UNKNOWN_ELF_GCC=riscv64-unknown-elf-gcc-8.3.0-2020.04.0-x86_64-linux-ubuntu14.tar.gz
wget https://static.dev.sifive.com/dev-tools/${RISCV64_UNKNOWN_ELF_GCC}
tar -xvf ${RISCV64_UNKNOWN_ELF_GCC} --strip-components=1 -C ${RISCV}

# Clone ariane repo
git clone --recursive https://github.com/openhwgroup/cva6.git
cd cva6

# Install fesvr
# The repo script does fine with this
ci/make-tmp.sh
ci/install-fesvr.sh

# Build RISCV tests
# The repo script does fine with this
ci/build-riscv-tests.sh

# Generate verilator binary
make verilate

# Run test
work-ver/Variane_testharness tmp/riscv-tests/build/isa/rv64um-v-divuw
