#!/bin/bash

# This script creates the entire sequence of commands (i.e.,  Dockerfiles, bash and R scripts) needed to build a TBio Locker/Docker image based on
# the list of steps specified below. This process triggers the generation of many scripts, including all Dockerfiles,  based on shared environment 
# variables used only during the build. The approach reduces hard-coding and accommodates changes in the number and sequence of steps, especially 
# as individual Dockerfiles have been merged.

# Usage: ./build_scripts/generate_master_build_script.sh config_files/build_setup.sh > go_build.sh 2> err
# or run ./generate_build.sh

# In addition to the named Bash script, the outputs include Dockerfiles, R and Bash scripts in generated/. The Bash script goes through this sequence,
# as long as each steps succeeds:
# 1) checks for sufficient disk space, presence of the local target directory, etc.
# 2) copies all the scripts, config files and any other cached files to a cache directory shared by Docker-based and efs-based steps.
# 3) installs all apps and packages via `docker build` and `docker run` commands, with a local log file for each step.
# 4) starts the rsync to e.g. /opt_tbio_production/devtest/20231010
# 5) generates the script to build the self-contained image but does not start this automatically.

# Multiple scripts that semi-automate some of the steps before and after the build, especially finding sources for R packages and checking the installed
# versions, also use the common env vars.

# Assumptions:
# - See build_setup.sh.
# - Python 3 is installed.

# To do/check:
# add handling of dependencies flag in R package installation (generate_scripts.py R_package_install_script_v2)
# check gert installations
# check Execution halted, No method found
# split R package checking (R_check_install_script below) into multiple jobs, run in parallel
# use cpus=$(grep -c ^processor /proc/cpuinfo)

# vscode installation:
#10 6.910 + curl -fsSL https://deb.nodesource.com/setup_14.x
#10 6.997                               DEPRECATION WARNING
#10 6.997   Node.js 14.x is no longer actively supported!
#10 6.997   You will not receive security or critical stability updates for this version.


# 9353:#7 435.1 update-language: texlive-base not installed and configured, doing nothing!
# #10 6.997   Node.js 14.x is no longer actively supported!

set -e				# Fail on unexpected error.

build_setup=$1
if [[ ! `which python3` ]] ; then echo "python3 not found." >& 2 ; exit 1 ; fi    
build_script_dir=$(dirname "${BASH_SOURCE[0]}")
rootdir=$(dirname $(dirname $build_script_dir))

if [[ "$build_setup"=="" ]] ; then
    build_setup=$(find -L $rootdir -name build_setup.sh)
    if [[ "$build_setup" == "" ]] ; then echo "build_setup.sh not found." >& 2 ; exit 1 ; fi
else
    if [[ "$(basename $build_setup)" != "build_setup.sh" ]] ; then
        echo "Warning - expecting build_setup.sh." >& 2 
    fi
    if [[ ! -e $build_setup ]] ; then echo "$build_setup not found." >& 2 ; exit 1 ; fi
fi

source $build_setup # note: this wrecks $setup
mkdir -p $log_dir

if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$dockerfile_dir" == "" ]]; then echo "dockerfile_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$efs_cache_dir" == "" ]]; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$imagename" == "" ]]; then echo "imagename is not defined" >& 2 ; exit 1 ; fi

# R_package_list=$(find_local_file R_packages_list.txt $rootdir) #$config_file_dir)
#R_package_list=$rootdir/R/R_packages_list.txt

generate_R_installation_scripts() {
    # generate scripts for R and Python
    echo "generating scripts for R package installation" >& 2
    if [[ "$configureRepo_dot_R" == "" ]]; then echo "configureRepo_dot_R is not defined" >& 2 ; exit 1 ; fi
    if [[ "$check_R_packages_dot_sh" == "" ]]; then echo "check_R_packages_dot_sh is not defined" >& 2 ; exit 1 ; fi
    if [[ "$check_R_packages_dot_R" == "" ]]; then echo "check_R_packages_dot_R is not defined" >& 2 ; exit 1 ; fi
    if [[ "$install_biocmanager_dot_R" == "" ]] ; then echo "install_biocmanager_dot_R is not defined" >& 2 ; exit 1 ; fi
    #if [[ "$Bioconductor_version" == "" ]]; then echo "Bioconductor_version is not defined" >& 2 ; exit 1 ; fi
   
    # Python generates R and bash
    generator=$(find_local_file generate_scripts.py $build_script_dir)
    # echo "# generating $install_biocmanager_dot_R via $generator R_bioc_install_script"  >& 2
    # $generator R_bioc_install_script -b $build_setup -o $dockerfile_dir/$install_biocmanager_dot_R

    # #generator=$(find_local_file generate_scripts.py $rootdir)
    # echo "# generating $install_R_packages_dot_R via $generator R_package_install_script_v2"  >& 2
    # $generator R_package_install_script_v2 -i $R_package_list -b $build_setup -o $dockerfile_dir/$install_R_packages_dot_R

    echo "# generating $check_R_packages_dot_sh via $generator R_check_install_script"  >& 2
    $generator R_check_install_script -i $R_package_list -b $build_setup --language bash -o $dockerfile_dir/$check_R_packages_dot_sh

    echo "# generating $check_R_packages_dot_sh via $generator R_check_install_script"  >& 2
    $generator R_check_install_script -i $R_package_list -b $build_setup --language R -o $dockerfile_dir/$check_R_packages_dot_R
}


# generate scripts for R package init & install
#source $generate_scripts $build_setup
mkdir -p $dockerfile_dir # originally held only dockerfiles; needs a new name
# generate_R_installation_scripts

efs_setup=$efs_cache_dir/$(basename $build_setup)


generate_dockerfile_header() {
echo "generating common header for Dockerfiles" >& 2
cat <<'EOF' > dockerfile_header
# syntax=docker/dockerfile:1
ARG INPUT_IMAGE
FROM ${INPUT_IMAGE}

# Set up Environment
ARG http_proxy http://proxy-server.bms.com:8080
ARG HTTP_PROXY http://proxy-server.bms.com:8080
ARG https_proxy http://proxy-server.bms.com:8080
ARG HTTPS_PROXY http://proxy-server.bms.com:8080
ARG ftp_proxy http://proxy-server.bms.com:8080
ARG FTP_PROXY http://proxy-server.bms.com:8080
ARG no_proxy .bms.com,169.254.169.254,localhost
ARG NO_PROXY .bms.com,169.254.169.254,localhost
ARG DEBIAN_FRONTEND=noninteractive
EOF
}
generate_dockerfile_header

#docker_build_args="" # dev
docker_build_args="--force-rm=true --no-cache" #prod # --squash=true 
# squash was not working in earlier image builds, and buildx ignores it

output_docker_build_steps() {
    # create one or more Dockerfiles from a single bash script.
    script=$1
    dir=${2:-$build_script_dir}
    path=$dir/$script
    # echo "docker build: $script" >& 2
    if [[ ! -e $path ]] ; then echo "$path not found" >& 2 ; return ; fi
    basename=$(basename $path)
    cmd="source $path $build_setup &> $log_dir/$basename.log"
    # Every "docker" bash script (e.g. docker/add_package_libraries.sh) generates one or more temp dockerfiles.
    # This function adds a common header and renames the files.
    for tempdockerfile in $($cmd) ;  do
        dockerfile=Dockerfile_$(printf "%02d" $dockerfile_num)
        new_image=$tempdockerimageprefix$(printf "%02d" $dockerfile_num)
        # if prefix is temp_, images will be labeled temp_01, temp_02 etc.
        new_image="local:$new_image"
        cat dockerfile_header $tempdockerfile > $dockerfile_dir/$dockerfile
        rm $tempdockerfile
        echo "# $basename" # comment for master bash script - could be appended to Dockerfile name
        echo "docker buildx build $docker_build_args -f $dockerfile_dir/$dockerfile --build-arg INPUT_IMAGE=$current_image --tag $new_image . &> $log_dir/$dockerfile.log"
        # will remove intermediate images, comment out to keep intermediate images.
        if [[ $dockerfile_num != "1" ]] ; then
            echo "docker image rm $current_image # cleanup"
        fi
        ((dockerfile_num+=1))
        if [[ $dockerfile_num == "100" ]] ; then echo "there are not enough digits in 02d for $dockerfile_num temp docker images" >& 2 ; exit 1 ; fi
        echo "" # spacer
        current_image=$new_image
    done
}

output_docker_run_step() {
    # create a docker run wrapper for an individual bash script; most scripts called directly are permanent
    script=$1
    dir=${2:-$build_script_dir}
    path=$dir/$script
    mount_dir=$(dirname "${efs_cache_dir}")
    # echo "docker run: $script"  >& 2
    if [[ ! -e $path ]] ; then echo "$path not found" >& 2 ; return ; fi
    basename=$(basename $path)
    #echo "docker run -v /opt/tbio:/opt/tbio $current_image /bin/bash -c \"source $efs_cache_dir/build_setup.sh; $efs_cache_dir/$script\" &> $basename.log"
    # echo "docker run --rm -v /opt/tbio:/opt/tbio $current_image /bin/bash -c \"${efs_cache_dir}/$(echo ${path} | sed 's#./##1') $efs_setup\" &> $log_dir/$basename.log"
    echo "docker run --rm -v $BUILD_PREFIX:$BUILD_PREFIX $current_image /bin/bash -c \"${efs_cache_dir}/$(echo ${path} | sed 's#./##1') $efs_setup\" &> $log_dir/$basename.log"
    echo ""
}

output_local_run_step() {
    # output direct call but check if script is present
    script=$1
    dir=${2:-$build_script_dir}
    path=$dir/$script
    # echo "run local: $script" >& 2
    if [[ ! -e $path ]] ; then echo "$path not found." >& 2 ; return ; fi
    basename=$(basename $path)
    echo "$path $build_setup &> $log_dir/$basename.log"
    echo ""
}

dockerfile_num=1
current_image="ubuntu:24.04"
# tempdockerimageprefix=my_temp #__
tempdockerimageprefix=$temp_img_name

cat <<'EOF'
#!/bin/bash
set -e
export PATH=.:${PATH:-}
# echo "cp -f $build_setup $efs_setup"
EOF

# 2023/08 - now executed directly
# output_local_run_step        generate_scripts.sh # must run before copying files to efs

output_local_run_step       pre_build_checks.sh 
output_local_run_step       copy_files_to_efs_cache.sh
output_docker_build_steps   docker/create_initial_image.sh
output_docker_run_step      efs/check_build_area.sh
output_docker_build_steps   docker/add_package_libraries.sh
output_docker_build_steps   docker/add_apts.sh
output_docker_build_steps   docker/configure_java.sh
output_docker_build_steps   docker/load_oracle.sh
output_docker_build_steps   docker/install_julia.sh

# # run miscellany.sh before installing R packages, for RODBC
output_docker_build_steps   docker/miscellany.sh 

output_docker_run_step      efs/install_java_on_efs.sh
output_docker_run_step      efs/add_source_packages.sh
output_docker_run_step      python/install_python.sh

output_docker_run_step      efs/install_cmdstan_on_efs.sh

output_docker_run_step      R/build_r_from_source.sh

output_docker_run_step      R/install_r_packages.sh

# configure_kernels  must run after installing Python, R and conda
# This takes two steps because executables are not visible inside the image, but revisit with buildx mount
# 1. with docker run, create config files and save them to the cache
output_docker_run_step      efs/configure_kernels_generate.sh
echo "mv -f $efs_cache_dir/$jupyter_kernels_zip $dockerfile_dir/"
# 2. with docker build, unzip them in the image
output_docker_build_steps   docker/configure_kernels_copy.sh

#output_local_run_step       miscellany_cleanup.sh
rm -f dockerfile_header 

echo "docker tag $current_image $imagename"
# echo "# docker image rm $current_image"

# The result of these steps is a script that these steps lead to  
# the scrips will not run automatically
output_local_run_step        efs/rsync_latest_nfs_image.sh

# this step outputs commands that will create scripts and config files to build the self-contained image, but that step does not run automatically.
echo "build_scripts/self_contained_image/generate_script_for_self_contained_image.sh $build_setup > build_self_contained_image.sh 2> generate_script_for_self_contained_image.sh"
echo "chmod +x build_self_contained_image.sh"
