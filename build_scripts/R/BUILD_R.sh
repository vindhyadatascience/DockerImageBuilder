#!/bin/bash

set -e

if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_version" == "" ]]; then echo "R_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$build_binaries_dir" == "" ]] ; then echo "build_binaries_dir is undefined" >& 2 ; exit 1 ; fi
if [[ "$JAVA_HOME" == "" ]] ; then echo "JAVA_HOME is undefined" >& 2 ; exit 1 ; fi

prefix=$BUILD_PREFIX
rversion=$R_version #=$(basename $(pwd))

destdir=$build_binaries_dir/$rversion
rm -fr $destdir
mkdir -p $destdir

#make distclean

export CPPFLAGS="-I$prefix/include"
export LDFLAGS="-Wl,-rpath,$destdir/lib64,-rpath,$prefix/lib,-rpath,$prefix/lib64 -L$destdir/lib64 -L$prefix/lib -L$prefix/lib64"
./configure -q --prefix=$destdir --enable-R-shlib --with-pic --with-x --with-tcltk --enable-memory-profiling \
  --with-blas \
  --with-lapack

make all
# make -k check
# make pdf </dev/null
# make info </dev/null
make install

#2022.12.09
# export JAVA_HOME=$prefix/binaries/jdk-11.0.2 
#export JAVA_HOME=$prefix/binaries/jdk-$Java_version
export JAVA_HOME=$JAVA_HOME
export PATH=$destdir/bin:$JAVA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$JAVA_HOME/lib/server:${LD_LIBRARY_PATH:-}
. /home/rr_user/.domino-defaults

R CMD javareconf

