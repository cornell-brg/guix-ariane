#!/usr/bin/env bash
set -e

# Setup a working directory
export TOP=$HOME/tmp
mkdir -p ${TOP}
cd ${TOP}

# guix install gcc toolchain
guix install gcc-toolchain

# guix install verilator 4.110
cat > verilator-4.110.scm \
<<'END'
(use-modules (gnu packages fpga)
             (guix packages)
             (guix git-download))

(package
  (inherit verilator)
  (version "4.110")
  (source (origin
            (inherit (package-source verilator))
            (uri (git-reference
                   (url "https://github.com/verilator/verilator")
                   (commit (string-append "v" version))))
            (sha256 (base32 "1lm2nyn7wzxj5y0ffwazhb4ygnmqf4d61sl937vmnmrpvdihsrrq")))))
END

guix package --install-from-file=verilator-4.110.scm

# guix install python (not sure if needed)
guix install python

# guix install device tree compiler
guix install dtc

# TODO: install riscv toolchain (need to convert this to guix)
export RISCV=${TOP}/riscv
export PATH=${RISCV}/bin:${PATH}
mkdir -p ${RISCV}

# The install scripts use precompiled libs from sifive, but they at least work on our machine
# In theory they could be built from source or grabbed from a package manager
RISCV64_UNKNOWN_ELF_GCC=riscv64-unknown-elf-gcc-8.3.0-2020.04.0-x86_64-linux-ubuntu14.tar.gz
wget https://static.dev.sifive.com/dev-tools/${RISCV64_UNKNOWN_ELF_GCC}
tar -xvf ${RISCV64_UNKNOWN_ELF_GCC} --strip-components=1 -C ${RISCV}

# guix install riscv-pk
guix install riscv-pk

# guix install hello-static
cat > hello-static.scm \
<<'END'
(use-modules (gnu packages base)
             (guix build-system gnu))

(define hello-static
 (static-package hello))

hello-static
END

TMPDIR=$(guix build --target=riscv64-linux-gnu -f hello-static.scm)
ln -sf $TMPDIR/bin/hello

# clone Ariane
git clone --recursive https://github.com/openhwgroup/cva6.git

cd cva6

# TODO: package fesvr?
ci/make-tmp.sh
ci/install-fesvr.sh

# Generate verilator binary
make verilate -j64

# Run hello
work-ver/Variane_testharness $(which pk) ${TOP}/hello
