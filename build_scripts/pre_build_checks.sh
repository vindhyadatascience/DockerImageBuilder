#!/bin/bash 

# initial checks prior image build; no files copied or dirs created

set -e

# To clean everything first, do this: 
# docker system prune --all --force

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "Specify build setup script, likely build_setup.sh." >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$BUILD_PREFIX" == "" ]] ; then 
    echo "BUILD_PREFIX is not defined." >&2
    exit 1
fi

# 2023/01/09 added as as safety
if [[ -d $BUILD_PREFIX ]] ; then
  echo "destination dir $BUILD_PREFIX exists - delete it manually" >& 2
  exit 1
fi

# previously:
#    if ! rm -rf $BUILD_PREFIX ; then
#      echo "Unable to delete $BUILD_PREFIX
#      exit 1
#    fi


# 2023/01/11: check for sufficient available space

# df=$(df /opt/tbio/ --output=avail --block-size=1G |tail -n 1|sed 's/ //g')
# Fixed for Ubuntu 24.04: Check /opt instead of /opt/tbio which doesn't exist yet
df=$(df /opt --output=avail --block-size=1G |tail -n 1|sed 's/ //g')
if [[ "$df" -lt "$minfreegb" ]]; then
  echo "There is not enough free space in $(dirname ${BUILD_PREFIX}) ($df GB free, $minfreegb required)" >&2
  exit 1
else
  echo "$df GB free on $(dirname ${BUILD_PREFIX}) > $minfreegb required"  >&2
fi

# The following test avoid obvious mistakes for the BUILD_PREFIX setting.

# if echo $BUILD_PREFIX | grep -s -q '^/opt/tbio' ; then
#     echo "BUILD_PREFIX = $BUILD_PREFIX begins with /opt/tbio" >& 2
# else
#     echo "BUILD_PREFIX = $BUILD_PREFIX does not begin with /opt/tbio" >& 2
#     exit 1
# fi

#mkdir -p $BUILD_PREFIX
#cp setup.sh tmp
#cp -f setup.sh build_setup.sh $BUILD_PREFIX
#cp -f setup.sh build_setup.sh $cache_dir

echo "pre-build check OK" >& 2
