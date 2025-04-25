#!/bin/bash -x

# 2023/07/28: libmamba now fails for Anaconda, though it worked two weeks ago

# 2022.09.28 removed test (-t)
# 2022.09.28 added conda clean step
#sh $BUILD_PREFIX/transfer/Miniconda3-py39_4.11.0-Linux-x86_64.sh -b -p $BUILD_PREFIX/miniconda3  -t
#sh $BUILD_PREFIX/transfer/Anaconda3-2021.11-Linux-x86_64.sh -b -p $BUILD_PREFIX/Anaconda3  -t

set -e

setup=$1
if [[ ! "$setup" == "" ]] ; then
  if [[ ! -e "$setup" ]] ; then echo "$setup not found"  >& 2 ; exit 1 ; fi
    source $setup
fi

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$anaconda_installer" == "" ]] ; then echo "anaconda_installer is not defined" >& 2 ; exit 1 ; fi
if [[ "$miniconda_installer" == "" ]] ; then echo "miniconda_installer is not defined" >& 2 ; exit 1 ; fi

err=0

install_conda_version() {
    dir=$1 # e.g. $BUILD_PREFIX/miniconda3
    installer=$2 # e.g. http:...Anaconda3-2021.11-Linux-x86_64.sh
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
    # The Conda installations appear to always give a failure exit code even if they work. 
    # So, just check to see if the binaries are there.
    if [[ -x $binary ]] ; then
        echo "binary $dir/bin/conda found"
        # https://www.anaconda.com/blog/a-faster-conda-for-a-growing-community/
        cd $dir/bin
        ./conda update -q -y -n base conda
        #if [[ "$dir" == "$BUILD_PREFIX/Anaconda3" ]] ; then
        ./conda install -q -y -n base -c conda-forge conda-libmamba-solver
        ./conda config --set solver libmamba
        #fi
        ./conda clean -q --all -y >& 2
    else
	    echo "binary $dir/bin/conda not found"
	    err=1
    fi
}

install_conda_version $BUILD_PREFIX/miniconda3 $miniconda_installer
install_conda_version $BUILD_PREFIX/Anaconda3 $anaconda_installer

if ((err)) ; then
    echo "Some Conda installation failed." >& 2
    exit 1
else
    echo "Conda installation succeeded!" >& 2
    exit 0
fi

