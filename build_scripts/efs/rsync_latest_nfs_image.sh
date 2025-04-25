#!/bin/bash 

# incremental update: 
# rsync --verbose --size-only --dry-run -a /opt/tbio/domino_202309/ /opt_tbio_production/domino_202309 &> rsync.update.log

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "Specify build setup script, likely build_setup.sh." >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
dir=$(dirname $build_setup)

source $build_setup

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_production_dir" == "" ]] ; then echo "efs_production_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_production_file_archive_dir" == "" ]] ; then echo "efs_production_file_archive_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi

#nfs_name=$(basename $BUILD_PREFIX)
# BUILD_PREFIX=/opt/tbio/domino_202307 => domino_202307
# $efs_production_path should be e.g. /opt_tbio_production/domino_202307

# if [[ ! -d /opt_tbio_production ]] ; then echo "/opt_tbio_production is not available" >& 2 ; exit 1 ; fi

#if [[ -d /opt_tbio_production/$nfs_name ]] ; then
#    echo "/opt_tbio_production/$nfs_name exists. Please remove before running this script." >& 2
#    exit 1
#fi

if [[ -d $efs_production_dir ]] ; then echo "$efs_production_dir exists. Please delete it before running this script." >& 2 ; exit 1 ; fi

mkdir -p $efs_production_dir

if [[ ! -d $efs_production_dir ]] ; then echo "Unable to create $efs_production_dir ." >& 2 ; exit 1 ; fi

#if [[ ! -d /opt/tbio/$nfs_name ]] ; then
#    echo "Unable to find /opt/tbio/$nfs_name" >& 2
#    exit 1
#fi

from=$BUILD_PREFIX
to=$efs_production_dir
echo "rsyncing from $from/ to $to" >& 2
if rsync -a $from/ $to ; then
    echo "rsync of $from/ to $to succeeded" >& 2
else
    echo "rsync of $from/ to $to failed" >& 2
    exit 1
fi

from=$efs_cache_dir
to=$efs_production_file_archive_dir
echo "rsyncing from $from/ to $to" >& 2
if rsync -a $from/ $to ; then
    echo "rsync of $from/ to $to succeeded" >& 2
else
    echo "rsync of $from/ to $to failed" >& 2
    exit 1
fi

