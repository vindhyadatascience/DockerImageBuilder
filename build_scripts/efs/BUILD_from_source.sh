#!/bin/bash

# Generic open source builder.
if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi

extra_config="$1"

# make distclean

set -e

# ./configure --help

#if [[ ! -e configure ]]; then echo "configure not found" >& 2 ; exit 1 ; fi
#if [[ ! -x configure ]]; then echo "configure not executable" >& 2 ; exit 1 ; fi

export LDFLAGS="-Wl,-rpath,$BUILD_PREFIX/lib"
./configure --prefix=$BUILD_PREFIX $extra_config --quiet
make
# make check
make install
