#!/bin/bash

# installs cmdstan

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$build_binaries_dir" == "" ]]; then echo "build_binaries_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$cmdstan_version" == "" ]]; then echo "cmdstan_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$CMDSTAN_PATH" == "" ]]; then echo "CMDSTAN_PATH is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]]; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi

#https://github.com/stan-dev/cmdstan/releases/download/v2.33.0/cmdstan-2.33.0.tar.gz

baseurl=https://github.com/stan-dev/cmdstan/releases/download/v$cmdstan_version
file=cmdstan-$cmdstan_version.tar.gz
wget --quiet --no-clobber -P $efs_cache_dir $baseurl/$file
cd $build_binaries_dir
tar -xvf $efs_cache_dir/$file
# tar should result in the creation of $CMDSTAN_PATH
# using this path to make sure that env vars are concocordant
cd $CMDSTAN_PATH

ls -l bin/ # bin/stanc shouldn't exist yet
cpus=$(grep -c ^processor /proc/cpuinfo)
make build -j$cpus

# 2023/09/25 returns 1 if run without an option
$CMDSTAN_PATH/bin/stanc --version

echo "cmd installation succeeded" >& 2

