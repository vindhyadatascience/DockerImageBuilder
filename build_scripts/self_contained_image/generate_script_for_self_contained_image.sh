#!/bin/bash

set -e

# outputs the commands to launch the steps to make a self-contained image
# Assumes Python 3 is installed with conda
# paths of scripts being called may need to be corrected

# to do: add the ability to continue after making file list

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "Specify build setup script, likely build_setup.sh." >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
dir=$(dirname $build_setup)

source $build_setup

if [[ "$BUILD_PREFIX" == "" ]] ; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi
if [[ "$self_contained_image_cache" == "" ]] ; then echo "self_contained_image_cache is not defined" >& 2 ; exit 1 ; fi
#if [[ "$conda_python" == "" ]] ; then echo "conda_python is not defined" >& 2 ; exit 1 ; fi

#python=/opt/anaconda3/envs/dertia/bin/python
# can be run by root
#if [[ ! -e $conda_python ]] ; then echo "$conda_python not found." >& 2 ; exit 1 ; fi

source_dir=$BUILD_PREFIX #/opt/tbio/domino_202212

startdir=$(pwd)
root_cache_dir=$self_contained_image_cache
batch_file_dir=$root_cache_dir/batch_files
batch_file_done_dir=$root_cache_dir/batch_files_done
source_file_list=$root_cache_dir/source_file_list
batch_file_sizes=$root_cache_dir/batch_file_sizes

script_dir=$(dirname $(dirname "${BASH_SOURCE[0]}"))

# Build commands
# 1. functions of Python script
script_generator=$(find_local_file generate_scripts.py $script_dir)
make_rsync_batch_files="$script_generator sc_make_file_batches"
get_source_files="$script_generator sc_get_source_files"
# 2. separate bash script
docker_self_contained_rsync=$(find_local_file docker_self_contained_rsync_files.sh $script_dir)

# make batch files
# pass source dir and local dir for batch files
if ls $batch_file_dir/* > /dev/null 2> /dev/null ; then
  echo "CAUTION: there are files in $batch_file_dir" >& 2
  echo "file list may be out of sync"  >& 2
  echo "uncomment rm below if necessary"  >& 2
  # echo "rm -f $batch_file_dir/*"
fi
if [[ -e $source_file_list ]] ; then
  echo "CAUTION: $source_file_list exists" >& 2
  echo "file list may be out of sync"  >& 2
  echo "uncomment rm below if necessary"  >& 2
  # echo "rm -f $source_file_list"
fi

echo "#!/bin/bash"
echo "set -e"
echo "mkdir -p $batch_file_dir $batch_file_done_dir"
echo "# rm -f $batch_file_dir/* $source_file_list 2> /dev/null"

# step 1: make batch files
# Assumes Python 3 is installed.and the scripts 

# running setup.sh below overrides python exe
echo "# find the files to rsync"
cmd="$get_source_files --inputdir $source_dir -s $source_file_list &> get_source_files.log"
echo $cmd

# by default, this creates a file called source_files, excluding root dir:

# path	size
# transfer/README.txt	308
# transfer/Python-3.10.2_setup.py	116619

# make sure this dir is empty

# file_list is now the input
echo "# make batches of files to rsync"
cmd="$make_rsync_batch_files --file_sizes $source_file_list --outputfileprefix $batch_file_dir/rsync_batch &> $batch_file_sizes"
echo $cmd

# this makes individual batches to rsync in successive layers

# batch_files/rsync_batches.1
# batch_files/rsync_batches.2
# ...
# batch_files/rsync_batches.37

# make the image ; cycles through the batch files

cmd="$docker_self_contained_rsync $build_setup $batch_file_dir $batch_file_done_dir &> $root_cache_dir/docker_self_contained_rsync_files.log"
echo $cmd
# echo "cd $startdir"
#exit 0

#  maybe delete

find_local_file_dummy() {
    tempfile=$1
    tempdir=$2
    file=$(find -L $tempdir -name $tempfile)
    if [[ "$file" == "" ]] ; then 
        echo "$tempfile not found in $tempdir" >& 2
        exit 1
    else
        echo $file
        exit 0
    fi
}

