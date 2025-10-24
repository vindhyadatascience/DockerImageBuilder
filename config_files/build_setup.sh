#!/bin/bash

# Defines env vars needed only during Docker image build
# Expects setup.sh (permanent env var definitions) in the same directory.
# Some scripts names are now only invoked in generate_master_build_script.sh

# 2023/10/02 - single function to find local files, added check for multiple files found

#dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))
dir=$(dirname "${BASH_SOURCE[0]}")
setup=$dir/setup.sh
if [[ ! -e $setup ]] ; then echo "$setup not found." >& 2 ; exit 1 ; fi
source $setup
# source $r_config_file

if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$R_version" == "" ]]; then echo "R_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$Bioconductor_version" == "" ]]; then echo "Bioconductor_version is not defined" >& 2 ; exit 1 ; fi
if [[ "$imagename" == "" ]]; then echo "imagename is not defined" >& 2 ; exit 1 ; fi
if [[ "$Java_version" == "" ]]; then echo "Java_version is not defined" >& 2 ; exit 1 ; fi

self_contained_image_name=$imagename-SelfContained

# example
# export HTTP_PROXY=http://proxy-server.bms.com:8080
# export FTP_PROXY=http://proxy-server.bms.com:8080
# export https_proxy=http://proxy-server.bms.com:8080
# export http_proxy=http://proxy-server.bms.com:8080
# export no_proxy=.bms.com,169.254.169.254,localhost
# export NO_PROXY=.bms.com,169.254.169.254,localhost
# export HTTPS_PROXY=http://proxy-server.bms.com:8080
# export ftp_proxy=http://proxy-server.bms.com:8080

# export R_repo_bioconductor=https://bioconductor.org/packages/$Bioconductor_version/bioc
# export R_repo_bioconductor_experimental=https://bioconductor.org/packages/$Bioconductor_version/data/experiment
# export R_repo_bioconductor_annotation=https://bioconductor.org/packages/$Bioconductor_version/data/annotation
# export R_repo_bioconductor_bms=https://pm.rdcloud.bms.com/bioconductor/packages/$Bioconductor_version/bioc

# export R_png_checkum=1e97887d1fc64f7c3a92a1626b97fcd7 # was hard-coded
export R_png_checkum=6dcd7e5e5645774d6a5db090d7cc2e54

export anaconda_installer=https://repo.anaconda.com/archive/Anaconda3-2023.07-2-Linux-x86_64.sh
export miniconda_installer=https://repo.anaconda.com/miniconda/Miniconda3-py311_23.5.2-0-Linux-x86_64.sh
export miniforge_installer=https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Mambaforge-24.7.1-0-Linux-x86_64.sh

export R_studio_drivers_url=https://cdn.rstudio.com/drivers/7C152C12/installer/rstudio-drivers_2024.03.0_amd64.deb
export R_studio_server_url=https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2024.04.2-764-amd64.deb


export domino_zip_url=https://github.com/dominodatalab/workspace-configs/archive/2021q1-v1.zip

# avoid clobbering 23/09
export efs_cache_dir=${BUILD_PREFIX}/cache
export efs_src_dir=$efs_cache_dir/src # in previous builds, this was under build_prefix
export build_binaries_dir=${BUILD_PREFIX}/binaries
export build_bin_dir=${BUILD_PREFIX}/bin
# export efs_production_dir=$BUILD_PREFIX/prod
export efs_production_file_archive_dir=$efs_production_dir/cache #/opt_tbio_production/devtest/$(basename $BUILD_PREFIX)/cache

export openjdk_url=https://download.java.net/java/GA/jdk${Java_version}/69cfe15208a647278a19ef0990eea691/12/GPL/openjdk-${Java_version}_linux-x64_bin.tar.gz

export minfreegb=75 # min GB free on /opt/tbio needed to start build
export local_cache_dir=local_cache # local dir for large files, previously transfer
export local_scripts_dir=build_scripts # scripts used to build image
export dockerfile_dir=generated
export self_contained_image_cache=self_contained_workspace # note: local; don't use leading ./ since it's repeated in docker_self_contained_rsync

# expecting same paths in local and efs cache
export local_R_package_cache=$local_cache_dir/r_package_tarballs #/src/contrib
export efs_R_package_tar=$efs_cache_dir/r_package_tarballs.tar
export jupyter_kernels_zip=jupyter_kernels.zip
export jupyter_kernels_dir=/home/rr_user/.local/share/jupyter/kernels

export R_src_dir=$efs_src_dir/$R_version
export R_local_repo=$R_src_dir/r_package_tarballs
export R_tarball_dest=tar-balls/src/contrib
export R_tarball_src=r_package_tarballs/src/contrib

export R_package_list=R_packages_list.txt
export configureRepo_dot_R=configureRepo.R
export install_R_packages_dot_R=install_R_packages.R
export install_biocmanager_dot_R=install_biocmanager.R
export check_R_packages_dot_sh=check_R_packages.sh
export check_R_packages_dot_R=check_R_packages.R
# export check_if_package_is_installed_dot_R=check_if_package_is_installed.R

export conda_python=/opt/anaconda3/envs/dertia/bin/python

# export saige_tar_file=SAIGE_0.36.5_R_x86_64-pc-linux-gnu.tar.gz
export saige_tar_file=v0.36.3.1.tar.gz

# utils to find files during build, makes editing convenient

# generated scripts are likely to exist already
make_numbered_file_backup_or_quit() {
    file=$1
    if [[ -e $file ]] ; then
        #echo "WARNING: $file exists - attempting to create a numbered backup"
        if cp --backup=numbered --force $file $file 2> /dev/null ; then
            echo "created a numbered backup of $file" >& 2
        else
            echo "failed to make a backup of $file" >& 2
            exit 1
        fi
    else
        echo "$file not found" >& 2
        exit 1
    fi
}

find_local_file() {
    tempfile=$1
    tempdir=$2
    file=$(find $tempdir -name $tempfile)
    if [[ "$file" == "" ]] ; then
        echo "$tempfile not found in $tempdir" >& 2
        exit 1
    fi
    N_files_found=${#file[@]} >& 2
    #echo "N_files_found=$N_files_found" >& 2
    if [[ "$N_files_found" == "0" ]] ; then
        #if [[ "$file" == "" ]] ; then 
        echo "$tempfile not found in $tempdir" >& 2
        exit 1
    elif [[ "$N_files_found" == "1" ]] ; then
        echo $file
        exit 0
    else
        echo "multiple files named $tempfile found in $tempdir" >& 2
        exit 1
    fi
}

# future replacement for calls in scripts that generate Dockerfiles

temp_docker_file() {
    temp=$(mktemp -u)
    echo $temp
    #echo 0
}
