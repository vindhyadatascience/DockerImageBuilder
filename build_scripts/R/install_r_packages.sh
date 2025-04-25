#!/bin/bash

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "Specify build setup script, likely build_setup.sh." >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi

# install IRkernel
R -e "install.packages('IRkernel', repos='https://cloud.r-project.org/')"

## Source env variables for R package installation.
source $BUILD_PREFIX/rpkg_config.sh

## Begin R package installation
time /usr/bin/Rscript $efs_cache_dir/build_scripts/R/install_r_packages2.R  $BUILD_PREFIX/binaries/$R_version/lib/R/library