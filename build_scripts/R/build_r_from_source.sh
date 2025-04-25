#!/bin/bash

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "Specify build setup script, likely build_setup.sh." >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$R_version" == "" ]]; then echo "R_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_src_dir" == "" ]]; then echo "R_src_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_png_checkum" == "" ]]; then echo "R_png_checkum is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]] ; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi

rm -fr $R_src_dir
temp_src_dir=$(dirname $R_src_dir)
mkdir -p $temp_src_dir
#R_tar=$(efs_cache_path $R_version.tar.gz)
# R_tar=$(find_local_file $R_version.tar.gz $efs_cache_dir)

# Download R source package
echo $R_version
R_prefix=$(echo $R_version | cut -d'.' -f1)
# https://cran.r-project.org/src/base/R-4/R-4.3.1.tar.gz
R_dl_link="https://cran.r-project.org/src/base/$R_prefix/$R_version.tar.gz"
cd $temp_src_dir
wget --quiet --no-clobber $R_dl_link

R_tar=$(find_local_file $R_version.tar.gz $efs_cache_dir)
tar xfz $R_tar

# cd $temp_src_dir
# tar xfz $R_tar

if [[ ! -d $R_src_dir ]] ; then
    echo "$R_src_dir not found after tar xfz $R_tar." >& 2
    exit 1
fi

#cp $(efs_cache_path BUILD_R.sh) $R_src_dir/BUILD
cp $(find_local_file BUILD_R.sh $efs_cache_dir) $R_src_dir/BUILD

cd $R_src_dir

# fix problem in png code.
# 2023/05/14: this consist of changing getOption("bitmapType") to "cairo" (multiple reference)
# This was previously hard-coded, but src/library/grDevices/R/unix/png.R changed from R 4.2.3 to R 4.3.0

file=src/library/grDevices/R/unix/png.R
if [[ -r $file ]] ; then
    mv -f $file $file.bak
    sed 's/getOption("bitmapType")/"cairo"/' $file.bak > $file
    echo "Verify that png default was changed to cairo: diff $R_src_dir/$file.bak $R_src_dir/$file" >& 2
    # 2023/05 this works - see diff below 
    
    png_md5=$(md5sum $file | cut -f 1 -d ' ')
    if [[ "$png_md5" != "$R_png_checkum" ]] ; then
        echo "Invalid checksum for $file" >& 2
        exit 1
    fi
    #else
    # 	cp --backup=numbered $(efs_cache_path png.R.cairo.default) src/library/grDevices/R/unix/png.R
    #fi
else
    echo "Warning: $file not found - png default could not be changed to cairo" >& 2
    exit 1
fi

# > diff /opt/tbio/cache/src/R-4.3.1/src/library/grDevices/R/unix/png.R.bak /opt/tbio/cache/src/R-4.3.1/src/library/grDevices/R/unix/png.R
#  <     if(missing(type)) type <- getOption("bitmapType")
#  >      if(missing(type)) type <- "cairo"
#  <     type <- if(!missing(type)) match.arg(type) else getOption("bitmapType")
#  >      type <- if(!missing(type)) match.arg(type) else "cairo"
#  <     type <- if(!missing(type)) match.arg(type) else getOption("bitmapType")
#  >      type <- if(!missing(type)) match.arg(type) else "cairo"
#  <     type <- if(!missing(type)) match.arg(type) else getOption("bitmapType")
#  >      type <- if(!missing(type)) match.arg(type) else "cairo"

chmod 755 BUILD
if ./BUILD &> build.log ; then
    echo R built successfully.
    exit 0
else
    echo R failed to build.
    exit 1
fi
