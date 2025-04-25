#!/bin/bash 

# copy files to cache; incomplete
# to do: copy config files to efs cache

set -e
export PATH=.:${PATH:-}

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "Specify build setup script, likely build_setup.sh." >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
build_config_dir=$(dirname $build_setup)
source $build_setup

if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$local_cache_dir" == "" ]] ; then echo "local_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_R_package_tar" == "" ]] ; then echo "efs_R_package_tar is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_src_dir" == "" ]] ; then echo "efs_src_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$local_R_package_cache" == "" ]] ; then echo "local_R_package_cache is not defined" >& 2 ; exit 1 ; fi
if [[ "$build_bin_dir" == "" ]] ; then echo "build_bin_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$build_binaries_dir" == "" ]] ; then echo "build_binaries_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$local_scripts_dir" == "" ]] ; then echo "local_scripts_dir is not defined" >& 2 ; exit 1 ; fi
#if [[ "$build_config_dir" == "" ]] ; then echo "build_config_dir is not defined" >& 2 ; exit 1 ; fi

# for temp in $local_scripts_dir $local_scripts_dir/efs build_scripts/docker $local_cache_dir $local_R_package_cache ; do
for temp in $local_scripts_dir $local_scripts_dir/efs build_scripts/docker $local_cache_dir ; do

  if [[ ! -d $temp ]] ; then echo "$temp not found" >& 2 ; exit 1 ; fi
done

mkdir -p $BUILD_PREFIX 
mkdir -p $efs_cache_dir $efs_src_dir $build_binaries_dir  $build_bin_dir 

# sticking with practice from previous builds for env vars that will persist, but not build-only env vars
/bin/cp -f $build_config_dir/setup.sh $BUILD_PREFIX/ 


#/bin/cp -f $local_scripts_dir/setup.sh $efs_cache_dir/
#/bin/cp -f $local_scripts_dir/setup.sh $efs_cache_dir/
/bin/cp -f -r --update $build_config_dir/* $local_scripts_dir $local_cache_dir $dockerfile_dir $efs_cache_dir/ 

# Copy R package config
/bin/cp -f $build_config_dir/rpkg_config.sh $BUILD_PREFIX/
/bin/cp -f $build_config_dir/R_packages/rpkgs.txt $BUILD_PREFIX/


cat > $efs_cache_dir/README.txt <<EOF
This folder contains large files needed to build the Docker image and NFS mounted filesystem that are not 
stored in the git repository. It is also used as a way to transfer files between the primary source folder on an EC2 instance to the NFS filesystem.
EOF

pwd=$(pwd)
# previously: tar --update --file $efs_R_package_tar $local_R_package_cache
# running tar within tar file directory avoid assumptions about prefixes
# cd $local_R_package_cache && tar --update --file $efs_R_package_tar * && cd $pwd
# tar file now contains JunctionSeq_1.17.0.tar.gz etc. without path/prefix

# cp -f -p torch_test.py $BUILD_PREFIX/transfer

echo "files copied to efs cache OK" >& 2
