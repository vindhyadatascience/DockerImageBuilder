#!/bin/bash -x

version=$(basename $(pwd) | tr 'A-Z' 'a-z' )
build_prefix=${BUILD_PREFIX:-/i/dont/exist/fix/me}
prefix=$build_prefix/binaries/$version
make distclean

export LDFLAGS="-L $prefix/lib -Wl,-rpath,$prefix/lib -L $build_prefix/lib -Wl,-rpath,$build_prefix/lib"
export CPPFLAGS="-I $prefix/include"
export LIBDIR=$prefix/lib

./configure --prefix=$prefix \
            --exec-prefix=$prefix \
	    --with-openssl=$build_prefix \
            --enable-loadable-sqlite-extensions \
            --enable-shared \
            --enable-big-digits 

make
# make test </dev/null
make install

export PATH=$prefix/bin:$PATH
err=0

if ! ../pip_install.sh `which python3`
then
    err=1
fi

cd ../liulab-mageck-c491c3874dca 
if ! python3 setup.py install 
then
    err=1
fi

cd ../liulab-mageck_nest-e4a34e45c2e7
if ! python3 setup.py install 
then
    err=1
fi

exit $err
