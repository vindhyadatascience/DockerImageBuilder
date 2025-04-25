#!/bin/bash

# note: need to make python a symbolic link to python3 to override system python (v2)

# verify that *setup.py contain a reference to the new image path e.g. /domino_202210 
# to do: automate the update and the test

# openssl fails due to
# ../test/recipes/80-test_ssl_new.t ..................
# Dubious, test returned 1 (wstat 256, 0x100)

set -e

setup=$1
if [[ ! "$setup" == "" ]] ; then
  if [[ ! -e "$setup" ]] ; then echo "$setup not found"  >& 2 ; exit 1 ; fi
    source $setup
fi

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is undefined" >& 2 ; exit 1 ; fi
if [[ "$efs_src_dir" == "" ]] ; then echo "efs_src_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
#if [[ "$efs_binaries_dir" == "" ]] ; then echo "efs_binaries_dir is not defined" >& 2 ; exit 1 ; fi
#if [[ "$efs_R_package_tar" == "" ]] ; then echo "efs_R_package_tar is not defined" >& 2 ; exit 1 ; fi

# Parse Python versions
#PYTHON_VERSION="2.7.18,3.10.6,3.10.2,3.9.10,3.8.12"
echo "about to run $PYTHON_VERSION" >& 2
IFS=',' read -r -a PYTHON_VERSIONS <<< "$PYTHON_VERSION"
echo "about to run $PYTHON_VERSIONS" >& 2

err=0

cd $efs_src_dir

# Function to download a file if it doesn't exist
download_file() {
    local url=$1
    local output_file=$2
    if [ ! -f "$output_file" ]; then
        echo "Downloading $url..."
        wget -q "$url" -O "$output_file"
        if [ $? -eq 0 ]; then
            echo "Successfully downloaded $(basename $output_file)"
        else
            echo "Failed to download $(basename $output_file)"
            return 1
        fi
    else
        echo "$(basename $output_file) already exists. Skipping download."
    fi
    return 0
}

# Updated package versions and URLs
packages=(
    "https://files.pythonhosted.org/packages/b2/40/4e00501c204b457f10fe410da0c97537214b2265247bc9a5bc6edd55b9e4/setuptools-44.1.1.zip"
    "https://sourceforge.net/projects/mageck/files/0.5/mageck-0.5.9.5.tar.gz"
    "https://files.pythonhosted.org/packages/ce/ea/9b445176a65ae4ba22dce1d93e4b5fe182f953df71a145f557cffaffc1bf/pip-19.3.1.tar.gz"
)

for package_url in "${packages[@]}"; do
    filename=$(basename "$package_url")
    download_file "$package_url" "$efs_cache_dir/$filename"
    if [ $? -ne 0 ]; then
        err=1
        echo "Failed to download $filename. Exiting."
        exit 1
    fi
    if [[ $filename == *.tar.gz ]]; then
        tar xfz $(find_local_file $filename $efs_cache_dir)
        base=$(echo $filename | sed 's/.tar.gz//')
    elif [[ $filename == *.zip ]]; then
        unzip -o -q $(find_local_file $filename $efs_cache_dir)
        base=$(echo $filename | sed 's/.zip//')
    else
        echo "Unsupported file format for $filename" >& 2
        continue
    fi
    if [[ "$base" == "mageck-0.5.9.5" ]] ; then
	    base=liulab-mageck-c491c3874dca
        # also on the first line with tar --list -f 
        # liulab-mageck-ef7c39474ed0/
    fi
    #cp $(efs_cache_path python_module_build.sh) $base/BUILD
    cp $(find_local_file python_module_build.sh $efs_cache_dir) $base/BUILD
    chmod 755 $base/BUILD
done

# contents of python_module_build.sh, now $base/BUILD
# prefix=${BUILD_PREFIX:-/usr/local}
# python=${PYTHON_FOR_BUILD:-/usr/bin/python}
# $python setup.py clean --all
# $python setup.py build
# $python setup.py check
# $python setup.py install

# Install MAGeCK-NEST
cd $efs_src_dir
wget --quiet --no-clobber https://bitbucket.org/liulab/mageck_nest/get/e4a34e45c2e7.zip
unzip -u -o e4a34e45c2e7.zip

dest=$efs_src_dir/pip_install.sh
if [[ ! -e $dest ]] ; then 
    # source=$(efs_cache_path pip_install.sh)
    source=$(find_local_file pip_install.sh $efs_cache_dir)
    # cp: will not overwrite just-created '/opt/tbio/cache/src/pip_install.sh' with '/opt/tbio/cache/utils/pip_install.sh'
    if [[ ! "$source" == "$dest" ]] ; then 
        cp -f $source $efs_src_dir
    fi
fi
chmod 755 $dest

# The script pip_install.sh contains the list of Python packages to be installed for all Pythons.

#build_script=$(efs_cache_path efs_build.sh)
build_script=$(find_local_file efs_build.sh $efs_cache_dir)



# Download OpenSSL
openssl_version="3.3.2"
openssl_url="https://github.com/openssl/openssl/releases/download/openssl-${openssl_version}/openssl-${openssl_version}.tar.gz"
download_file "$openssl_url" "$efs_cache_dir/openssl-${openssl_version}.tar.gz"
if [ $? -ne 0 ]; then
    err=1
    echo "Failed to download OpenSSL. Exiting."
    exit 1
fi

# Download Python versions
cd $efs_src_dir
for version in "${PYTHON_VERSIONS[@]}"; do
    python_url="https://www.python.org/ftp/python/${version}/Python-${version}.tgz"
    download_file "$python_url" "$efs_cache_dir/Python-${version}.tgz"
    if [ $? -ne 0 ]; then
        err=1
        echo "Failed to download Python ${version}. Exiting."
        exit 1
    fi
done

#build_script=$(efs_cache_path efs_build.sh)
build_script=$(find_local_file efs_build.sh $efs_cache_dir)

# add openssl to python version array
# PYTHON_VERSIONS=(openssl-${openssl_version} "${PYTHON_VERSIONS[@]}")

err=0
# Python-3.6.15.tgz \
# Python 3 installations require openssl; otherwise, these steps could run in parallel
# for tarball in openssl-1.1.1d.tar.gz \
    # Python-2.7.18.tgz \
    # Python-3.8.12.tgz \
    # Python-3.9.10.tgz \
    # Python-3.10.2.tgz \
    # Python-3.10.6.tgz
for my_pkg in "${PYTHON_VERSIONS[@]}"
do
    echo $my_pkg
    cd $efs_src_dir
    if [[ $my_pkg == openssl* ]]; then
        tarball=$my_pkg.tar.gz
    else
        tarball=Python-$my_pkg.tgz
    fi
    #cp $BUILD_PREFIX/transfer/$tarball $BUILD_PREFIX/tar-balls
    #tar xfz $(efs_cache_path $tarball)
    tar xfz $(find_local_file $tarball $efs_cache_dir)
    base=$(echo $tarball | sed -e 's/\.tar\.gz$//' -e 's/\.tgz$//')
    cp $build_script $base/BUILD
    setup=$(find -L $efs_cache_dir -name ${base}_setup.py)
    if [[ ! "$setup" == "" ]] ; then 
	    cp --backup=numbered $setup $base/setup.py
    fi
    cd $base
    chmod 755 ./BUILD
    if ./BUILD > build.log 2>&1 ; then
	    echo "Build of $base succeeded." >& 2
    else
	    err=1
	    echo "Build of $base failed" >& 2
    fi
done


if ((err)) ; then
    echo "Installation(s) failed."  >& 2
    exit 1
else
    echo "Installations succeeded!"  >& 2
    exit 0
fi