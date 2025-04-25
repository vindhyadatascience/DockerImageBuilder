#!/bin/bash

# Generic cmake builder.
if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi

extra_config="$1"

# make distclean

set -e

mkdir build
cd build

# cmake ..
cmake -DCMAKE_BUILD_TYPE=Release .. --debug-output
make
make install
# cmake ..
# cmake --build .
# cmake --build . --target install

# ./configure --help

#if [[ ! -e configure ]]; then echo "configure not found" >& 2 ; exit 1 ; fi
#if [[ ! -x configure ]]; then echo "configure not executable" >& 2 ; exit 1 ; fi

# export LDFLAGS="-Wl,-rpath,$BUILD_PREFIX/lib"
# ./configure --prefix=$BUILD_PREFIX $extra_config --quiet
# make
# # make check
# make install