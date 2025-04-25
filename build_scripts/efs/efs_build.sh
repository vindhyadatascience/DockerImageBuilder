#!/bin/bash -x

# Previously separate scripts for each version of Python and openssl
# the argument to this script should be one of 2.7.10, 3.9.6, etc.

# note: --disable-test-modules added for Python 3

set -e

if [[ "$build_binaries_dir" == "" ]] ; then echo "build_binaries_dir is undefined" >& 2 ; exit 1 ; fi
if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi

version=$(basename $(pwd) | tr 'A-Z' 'a-z')
# e.g. python-3.8.12
major_version=$(echo $version | cut -f 1 -d .)
# python-2

# make distclean # this has failed for every package 

if [[ "$major_version" == "python-2" ]] ; then
    prefix=$build_binaries_dir/$version
    export LDFLAGS="-Wl,-rpath,$prefix/lib"
    ./configure -q --prefix=$prefix --exec-prefix=$prefix --enable-shared --enable-big-digits --with-threads
elif [[ "$major_version" == "python-3" ]] ; then
    prefix=$build_binaries_dir/$version
    if [[ "$version" == "python-3.8.12" ]] ; then
        export LDFLAGS="-L$prefix/lib -Wl,-rpath,$prefix/lib -L$BUILD_PREFIX/lib -Wl,-rpath,$BUILD_PREFIX/lib"
        #extra_config=""
    else
        #extra_config="--disable-test-modules"
        export LDFLAGS="-L $prefix/lib -Wl,-rpath,$prefix/lib -L $BUILD_PREFIX/lib -Wl,-rpath,$BUILD_PREFIX/lib"
    fi
    export CPPFLAGS="-I $prefix/include"
    export LIBDIR=$prefix/lib
    apt-get install build-essential zlib1g-dev libtinfo-dev libssl-dev libreadline-dev libffi-dev
    ssl_loc=$(which openssl)
    ./configure -q --prefix=$prefix --exec-prefix=$prefix --enable-loadable-sqlite-extensions --enable-shared --enable-big-digits --enable-optimizations # --with-openssl=$ssl_loc
elif [[ "$major_version" == "openssl-3" ]] ; then
    prefix=$BUILD_PREFIX
    ./config --prefix=$prefix -v
    #  -v     Verbose mode, show the exact Configure call that is being made.
else
    echo "unknown condition $major_version" >& 2
    exit 1
fi

make 

# previously the default - restore
echo "restore make test after debugging"  >& 2
# make test </dev/null 2> /dev/null

make install 2> /dev/null

export PATH=$prefix/bin:$PATH
err=0

if [[ "$major_version" == "python-2" ]] ; then
    export PYTHON_FOR_BUILD=$(which python)
    curdir=$(pwd)
    echo "$curdir"
    cd ../setuptools-44.1.1
    ./BUILD
    # cd ../pip-24.2
    # ./BUILD
    python -m ensurepip
    cd $curdir
    ../pip_install.sh `which python`
elif [[ "$major_version" == "python-3" ]] ; then
    ../pip_install.sh `which python3`
    cd ../liulab-mageck-c491c3874dca 
    python3 setup.py install
    cd ../liulab-mageck_nest-e4a34e45c2e7
    python3 setup.py install
elif [[ "$major_version" == "openssl-3" ]] ; then
    cp -f /etc/ssl/certs/* $prefix/ssl/certs
else
    "unknown condition $major_version" >& 2
    exit 1
fi
