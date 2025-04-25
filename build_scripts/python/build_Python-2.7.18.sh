#!/bin/bash

set -e

if [[ "$build_binaries_dir" == "" ]] ; then echo "build_binaries_dir is undefined" >& 2 ; exit 1 ; fi

version=$(basename $(pwd) | tr 'A-Z' 'a-z')
prefix=$build_binaries_dir/$version
make distclean

export LDFLAGS="-Wl,-rpath,$prefix/lib"

./configure --prefix=$prefix \
	    --exec-prefix=$prefix \
	    --enable-shared \
	    --enable-big-digits\
	    --with-threads
make 
# make test </dev/null
make install

export PATH=$prefix/bin:$PATH
export PYTHON_FOR_BUILD=$(which python)
curdir=$(pwd)
cd ../setuptools-75.1.0 || exit 1
./BUILD
cd ../pip-24.2 || exit 1
./BUILD
cd $curdir
../pip_install.sh `which python`
