#!/bin/bash 

# error during gdal build; this was happening in previous builds too
# GNUmakefile:159: recipe for target 'config.status' failed

set -e

# don't rely on env vars to be set by docker run command

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi
if [[ "$efs_src_dir" == "" ]] ; then echo "efs_src_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$build_bin_dir" == "" ]] ; then echo "build_bin_dir is not defined" >& 2 ; exit 1 ; fi

err=0

efs_cache_path_skip() {
    temp=$1
    file=$(find -L $efs_cache_dir -name $temp)
    if [[ "$file" == "" ]] ; then 
        echo "$temp not found in $efs_cache_dir" >& 2
        exit 1
    else
        echo $file
    fi
}

# gdal takes a long time to compile
# add-apt-repository ppa:ubuntugis/ppa
# apt-get update
# apt-get install -y gdal-bin libgdal-dev python3-gdal # instead of install gdal from source - 10-04-2024

# apt-get update
# apt-get install -v sqlite3 libsqlite3-dev

cmake --version

sources=(
    # "https://github.com/Kitware/CMake/releases/download/v3.30.4/cmake-3.30.4.tar.gz" # probably won't need
    "https://sqlite.org/2024/sqlite-autoconf-3460100.tar.gz" # good
    "https://download.osgeo.org/proj/proj-9.5.0.tar.gz" # good
    "https://github.com/OSGeo/gdal/releases/download/v3.7.3/gdal-3.7.3.tar.gz" # good
    "https://ftp.gnu.org/gnu/gsl/gsl-2.8.tar.gz" # good
    "https://github.com/igraph/igraph/releases/download/0.10.13/igraph-0.10.13.tar.gz" # needs updated cmake version
)
# for file in sqlite-autoconf-3310100 gdal-2.4.4 gsl-2.7.1 igraph-0.7.1 proj-5.2.0 JAGS-4.3.0 cmake-3.22.3 ; do
for source in "${sources[@]}"; do
    file=$(basename $source | sed 's/.tar.gz//')
    echo $file
    pwd
    wget --quiet --no-clobber $source
    # tarfile=$file.tar.gz
    tarfile=$(basename $source)
    # #temp=$(efs_cache_path $tarfile)
    # temp=$(find_local_file $tarfile $efs_cache_dir)
    cd $efs_src_dir
    pwd
    ls
    cp -f /$tarfile .
    echo "unzipping tarfile"
	tar xfz $tarfile
    tarfile=$efs_src_dir/$tarfile
    # cd /
    # echo "DONE"
	if [[ "$file" == sqlite-autoconf* ]] ; then
        temp=$(find_local_file BUILD_sqlite.sh $efs_cache_dir)
        #temp=$(efs_cache_path BUILD_sqlite.sh)
    elif [[ "$file" == cmake-* ]] ; then
        temp=$(find_local_file BUILD_cmake.sh $efs_cache_dir)
        echo "found $file"
        #temp=$(efs_cache_path BUILD_cmake.sh)
    elif [[ "$file" == gsl-* ]] ; then
        temp=$(find_local_file BUILD_from_source.sh $efs_cache_dir)
        echo "found $file"
    elif [[ "$file" == proj* ]] ; then
        temp=$(find_local_file BUILD_proj.sh $efs_cache_dir)
        echo "found $file"
    else
        #temp=$(efs_cache_path BUILD_from_source.sh)
        # temp=$(find_local_file BUILD_from_source.sh $efs_cache_dir)
        temp=$(find_local_file BUILD_with_cmake.sh $efs_cache_dir)
        echo "found $file"
    fi
    cp $temp $file/BUILD
    cd $file
    echo "Building $file now!"
    chmod 755 BUILD 
    extra_config=""
    if [[ "$file" == gdal* ]] ; then
	    extra_config="--with-sqlite3=$BUILD_PREFIX --with-crypto=no"
    elif [[ "$file" == gsl-* ]] ; then
	    extra_config="--disable-static"
    else
        extra_config=""
    fi
    if ./BUILD $extra_config >build.log 2>&1 ; then 
        rm $tarfile
    else
        # cat build.log
        echo "$file failed to build." >& 2
        echo "check $efs_src_dir/$file/build.log." >& 2
        err=1
    fi
    cd /
done

# # was cd $BUILD_PREFIX/src
# cd $efs_src_dir
# #tar xfz $(efs_cache_path phantomjs-2.1.1-linux-x86_64.tar.gz)
# tar xfz $(find_local_file phantomjs-2.1.1-linux-x86_64.tar.gz $efs_cache_dir)
# #tar xfz $BUILD_PREFIX/transfer/phantomjs-2.1.1-linux-x86_64.tar.gz

# This `ln`` led to a dead link in all previous builds since /opt/tbio/domino_2022... no longer exists
# /opt_tbio_production/domino_202203/bin/phantomjs -> /opt/tbio/domino_202203/src/phantomjs-2.1.1-linux-x86_64/bin/phantomjs
#rm -f $build_bin_dir/phantomjs
#ln -s $(pwd)/phantomjs-2.1.1-linux-x86_64/bin/phantomjs $build_bin_dir

# rm -f $build_bin_dir/phantomjs
# cp $(pwd)/phantomjs-2.1.1-linux-x86_64/bin/phantomjs $build_bin_dir/

if [[ "$err" == "0" ]] ; then
    echo "Success - source packages were installed OK!" >& 2
    exit 0
else
    echo "Some software failed to install."  >& 2
    exit 1
fi

