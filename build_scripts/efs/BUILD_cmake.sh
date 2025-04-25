#!/bin/sh

# Generic open source builder.

if [[ "$build_binaries_dir" == "" ]] ; then echo "build_binaries_dir is undefined" >& 2 ; exit 1 ; fi

version=$(basename $(pwd))

prefix=$build_binaries_dir/$version

mkdir -p $prefix

if [[ -r Makefile ]] ; then
    make clean
fi

rm -f CMakeCache.txt
# ./bootstrap --prefix=$prefix
# make
# make install

./bootstrap
make
make install
