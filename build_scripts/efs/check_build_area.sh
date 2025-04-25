#!/bin/bash

# Check if directories are seen in the images.
# was create_build_area.sh in previous builds

# relies on env vars to be set by docker run command

set -e

setup=$1
if [[ ! "$setup" == "" ]] ; then
  if [[ ! -e "$setup" ]] ; then echo "$setup not found"  >& 2 ; exit 1 ; fi
  source $setup
fi

#echo "# in efs_check_build_area.sh" >& 2

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_src_dir" == "" ]] ; then echo "efs_src_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$build_binaries_dir" == "" ]] ; then echo "build_binaries_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_R_package_tar" == "" ]] ; then echo "efs_R_package_tar is not defined" >& 2 ; exit 1 ; fi

#setup=$BUILD_PREFIX/build_setup.sh
#setup=$efs_cache_dir/build_setup.sh

#if [[ ! -r $setup ]] ; then echo "$setup not found" >& 2 ; exit 1 ; fi
#source $setup

for temp in $BUILD_PREFIX $efs_cache_dir $efs_src_dir $build_binaries_dir ; do
    if [[ ! -d $temp ]] ; then echo "$temp not found" >& 2 ; exit 1 ; fi
    #if [[ ! $(ls $temp/* 2> /dev/null) ]] ; then echo "$temp is empty" >& 2 ; exit 1 ; fi
done

# for temp in $efs_R_package_tar $efs_cache_dir/README.txt ; do
#     if [[ ! -r $temp ]] ; then echo "$temp not found" >& 2 ; exit 1 ; fi
# done

echo "Build area in the image is ready." >& 2
