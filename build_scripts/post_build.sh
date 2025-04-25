#!/bin/bash

# 2023/09 - new script for cleanup steps

setup=$1
if [[ "$setup" == "" ]] ; then
  dir=$(dirname "${BASH_SOURCE[0]}")
  setup=$(find -L $dir -name build_setup.sh)
  if [[ "$setup" == "" ]] ; then echo "$setup not found." >& 2 ; exit 1 ; fi
else
  if [[ ! -e "$setup" ]] ; then echo "$setup not found"  >& 2 ; exit 1 ; fi
  dir=$(dirname $setup)
fi

setup_script=$setup
source $setup

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
#if [[ "$self_contained_image_cache" == "" ]] ; then echo "self_contained_image_cache is not defined" >& 2 ; exit 1 ; fi
#if [[ "$dockerfile_dir" == "" ]]; then echo "dockerfile_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]]; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_production_file_archive_dir" == "" ]]; then echo "efs_production_file_archive_dir is not defined" >& 2 ; exit 1 ; fi
#if [[ "$imagename" == "" ]]; then echo "imagename is not defined" >& 2 ; exit 1 ; fi

mkdir -p $efs_production_file_archive_dir # /opt_tbio_production/domino_202309_files
log=$efs_production_file_archive_dir/build_logs.zip
# capture log files in cache
echo "find $efs_cache_dir/ -type f |grep "\.log$"|zip -u -@ $log"
echo "find $efs_cache_dir/ -type f -name BUILD |zip -u -@ $log"
echo "zip -u $log $efs_cache_dir/src/R-*/*.*"
echo "zip -u $log $efs_cache_dir/src/*/config*"
echo "zip -mT $log Dockerfile_*log"

# copy R tarballs to efs
echo "rsync -a $local_R_package_cache $efs_production_file_archive_dir"
