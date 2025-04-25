#!/bin/bash -x

set -e

setup=$1
if [[ ! "$setup" == "" ]] ; then
  if [[ ! -e "$setup" ]] ; then echo "$setup not found"  >& 2 ; exit 1 ; fi
    source $setup
fi

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$miniforge_installer" == "" ]] ; then echo "miniforge_installer is not defined" >& 2 ; exit 1 ; fi

err=0

install_miniforge() {
    dir=$1 # e.g. $BUILD_PREFIX/miniforge3
    installer=$2 # e.g. https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Mambaforge-24.7.1-0-Linux-x86_64.sh
    wget --no-clobber --quiet -P $efs_cache_dir/python $installer
    installer=$(basename $installer)
    cd $BUILD_PREFIX
    if [[ -d "$dir" ]] ; then 
        echo "$dir exists" >& 2
        echo "rm -fr $dir" >& 2
        exit 1
    fi
    sh $efs_cache_dir/python/$installer -b -p $dir
    binary=$dir/bin/conda
    if [[ -x $binary ]] ; then
        echo "binary $dir/bin/conda found"
        cd $dir/bin
        ./conda update -q -y -n base conda
        ./conda install -q -y -n base -c conda-forge conda-libmamba-solver
        ./conda config --set solver libmamba
        ./conda clean -q --all -y >& 2
    else
        echo "binary $dir/bin/conda not found"
        err=1
    fi
}

install_miniforge $BUILD_PREFIX/miniforge3 $miniforge_installer

if ((err)) ; then
    echo "Miniforge installation failed." >& 2
    exit 1
else
    echo "Miniforge installation succeeded!" >& 2
    exit 0
fi