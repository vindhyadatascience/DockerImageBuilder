#!/bin/bash

# Generic open source builder.

if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi

#make distclean
set -e

./configure --prefix=$BUILD_PREFIX --enable-readline --quiet
make
make install
