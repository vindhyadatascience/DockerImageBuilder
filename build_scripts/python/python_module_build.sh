#!/bin/sh 

set -e

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi

prefix=${BUILD_PREFIX:-/usr/local}
python=${PYTHON_FOR_BUILD:-/usr/bin/python}
echo "# running python module build $python " >& 2
$python setup.py clean --all
$python setup.py build
$python setup.py check
$python setup.py install

