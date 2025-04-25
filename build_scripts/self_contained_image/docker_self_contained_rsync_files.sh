#!/bin/bash

# self_contained_image_build

# NOTE: code expects at most a single container to be running

# 2023/10/02 - delete_container no longer necessary after adding --rm
# creating cleanup script
# renamed initial_copy to rsync_init_dirs

# Builds a self-contained image by gradually copying files from local build dir into containers
# 1. rsync only directories in the initial copy of the standard image
# 2. rsync regular files in batches
# 3. rsync any remaining files, namely symbolic links and R files with commas

# Uses local /opt/tbio as the source of files instead of /opt_tbio_production
# Also outputs cleanup_self_contained.sh.

# cmd=". $docker_self_contained_rsync_script $setup $batch_file_dir $batch_file_done_dir &> $root_cache_dir/docker_self_contained_rsync_files.log"

set -e

setup=$1
batch_file_dir=$2 # source
batch_file_done_dir=$3 # dest

if [[ "$setup" == "" ]] ; then echo "setup is not defined." >& 2 ; exit 1 ; fi
if [[ ! -e "$setup" ]] ; then echo "$setup not found"  >& 2 ; exit 1 ; fi

source $setup

if [[ "$imagename" == "" ]]; then echo "imagename is not defined" >& 2 ; exit 1 ; fi
if [[ "$self_contained_image_name" == "" ]]; then echo "self_contained_image_name is not defined" >& 2 ; exit 1 ; fi
if [[ "$self_contained_image_cache" == "" ]]; then echo "self_contained_image_cache is not defined" >& 2 ; exit 1 ; fi
if [[ "$BUILD_PREFIX" == "" ]]; then echo "BUILD_PREFIX is not defined" >& 2 ; exit 1 ; fi

# the destination path depends on the type of rsync
# dest_for_dir_sync=$(basename $BUILD_PREFIX)
dest_for_dir_sync=/opt/tbio
dest_for_file_sync=$BUILD_PREFIX

# inside the container, this will refer to the actual source
# local_vol_alias=/opt
local_vol_alias=/dummy
# source=$local_vol_alias/$(basename $BUILD_PREFIX)
source=$local_vol_alias

repo=local
standard_image=$imagename
final_image=$self_contained_image_name
initial_copy=$repo:rsync_init_dirs

img=$(docker images $final_image -q)
if [[ ! "$img" == "" ]] ; then echo "final image exists - exiting"  >& 2 ; exit 0 ; fi

# check if necessary scripts are present
dir=$(dirname "${BASH_SOURCE[0]}")
rsync_init_script=$(find_local_file rsync_init_dirs.sh $dir)
rsync_file_batch_sync_script=$(find_local_file rsync_file_batch.sh $dir)
rsync_final_script=$(find_local_file rsync_final.sh $dir)
cleanup_script=cleanup_self_contained.sh

if [[ -e $cleanup_script ]] ; then echo "$cleanup_script exists." >& 2 ; exit 1 ; fi

echo "#!/bin/bash" > $cleanup_script
echo "set -e" >> $cleanup_script

# the same dir is used for logs in container and local
log_dir=$self_contained_image_cache/rsync_logs
mkdir -p $log_dir

# expects batch files in batch_files, then moves them to batch_files_done
mkdir -p $batch_file_done_dir

# echo & execute command
exec_cmd() {
  cmd=$1
  echo $cmd >& 2
  output=$($cmd)
  echo $output
  return
}

start_container_detached() {
  img_id=$1
  echo "starting detached container for $img_id" >& 2


  cmd="docker run --rm -itd -v $dest_for_file_sync:$local_vol_alias --privileged $img_id /bin/bash"
  echo "$cmd &" >& 2
  # ampersand goes here
  
  container_id=$($cmd &)
  if [[ "$container_id" == "" ]] ; then echo "failed to start container from image $img_id" >& 2 ; exit 1 ; fi
  echo "started container $container_id from image $img_id" >& 2
  sleep 1
  #exec_cmd "disown"
  #sleep 1
  echo $container_id
  return
}

commit_running_container() {
  # note: it is problematic for the message to contain a space
  container=$1
  image=$2
  message=$3
  message=${message// /_}
  # commit the running container
  echo "commit the running container" >& 2
  if exec_cmd "docker commit --message $message $container $image" ; then
    echo "commit succeeded: $cmd" >& 2
  else
    echo "commit failed: $cmd" >& 2
    exit 1
  fi
}

stop_container() {
  # stop the running container
  local container=$1
  echo "stop the running container" >& 2
  if exec_cmd "docker stop $container" ; then
    echo "container $cmd stopped" >& 2
    sleep 1
  else
    echo "failed to stop container $cmdcmd" >& 2
    exit 1
  fi
}

iterate_no_batch_file() {
  input_image=$1
  local_script=$2
  message=$3
  output_image=$4
  image_script=$(basename $local_script)
  zipfile=$image_script.logs.zip
  env_opts="-e SOURCE=$source -e DEST=$dest_for_dir_sync -e RSYNC_LOG_DIR=$log_dir"

  echo "input_image=$input_image message=$message local_script=$local_script zipfile=$zipfile output_image=$output_image" >& 2
  container_id=$(start_container_detached $input_image)
  exec_cmd "docker cp $local_script $container_id:/tmp"
  exec_cmd "docker exec -w /tmp $env_opts $container_id /tmp/$image_script"
  exec_cmd "docker exec -w /tmp $container_id zip -r -mT $zipfile /tmp/$image_script ./$log_dir/"
  exec_cmd "docker cp $container_id:/tmp/$zipfile $log_dir/"
  exec_cmd "docker exec $container_id rm /tmp/$zipfile"
  
  # # Add symlinks for Python
  if [[ "$message" == "final_image" ]]; then
    exec_cmd "docker exec -w /tmp $container_id mkdir -p $BUILD_PREFIX/binaries/python-3.10.6/bin"
    exec_cmd "docker exec -w /tmp $container_id ln -s $BUILD_PREFIX/binaries/python-3.10.6/bin/python3.10 $BUILD_PREFIX/binaries/python-3.10.6/bin/python3"
    exec_cmd "docker exec -w /tmp $container_id ln -s $BUILD_PREFIX/binaries/python-3.10.6/bin/python3.10-config $BUILD_PREFIX/binaries/python-3.10.6/bin/python3-config"
  fi

  exec_cmd "commit_running_container $container_id $output_image $message"
  exec_cmd "docker stop $container_id"
}


iterate_with_file_batch() {
  input_image=$1 #container_id=$1
  local_script=$2
  batch_file=$3
  output_image=$4
  image_script=$(basename $local_script)
  batch_file_basename=$(basename $batch_file)
  zipfile=$batch_file_basename.logs.zip
  message=$batch_file_basename
  env_opts="-e SOURCE=$source -e DEST=$dest_for_file_sync -e RSYNC_LOG_DIR=$log_dir"
  echo "iteration: input_image=$input_image message=$message local_script=$local_script batch_file=$batch_file zipfile=$zipfile output_image=$output_image"
  container_id=$(start_container_detached $input_image)
  exec_cmd "docker cp $local_script $container_id:/tmp"
  exec_cmd "docker cp $batch_file $container_id:/tmp"
  exec_cmd "docker exec -w /tmp $env_opts $container_id /tmp/$image_script $batch_file_basename"
  exec_cmd "docker exec -w /tmp $container_id zip -r -mT $zipfile $batch_file_basename /tmp/$image_script ./$log_dir/"
  exec_cmd "docker cp $container_id:/tmp/$zipfile $log_dir/"
  exec_cmd "docker exec $container_id rm /tmp/$zipfile"
  exec_cmd "commit_running_container $container_id $output_image $message"
  exec_cmd "docker stop $container_id"
  echo "docker image rm $input_image" >> $cleanup_script
}
    
# check_if_new_image_exists
img=$(exec_cmd "docker images $initial_copy -q")
if [[ "$img" == "" ]] ; then
  echo "create initial copy $initial_copy" >& 2
  iterate_no_batch_file $standard_image $rsync_init_script "initial_copy" $initial_copy
else
  echo "initial copy exists - skipping" >& 2
fi

current_image=$initial_copy

for batch_file in $(ls $batch_file_dir/* 2> /dev/null|grep -v done) ; do
  echo "rsync batch $batch_file" >& 2
  batch_file_basename=$(basename $batch_file)
  new_image="$repo:$batch_file_basename"
  img=$(docker images $new_image -q)
  if [[ "$img" == "" ]] ; then
    iterate_with_file_batch $current_image $rsync_file_batch_sync_script $batch_file $new_image
  else
    echo "$new_image exists - skipping" >& 2
  fi
  current_image=$new_image
  mv $batch_file $batch_file_done_dir/
done
  
iterate_no_batch_file $current_image $rsync_final_script "final_image" $final_image

echo "docker image rm $current_image" >> $cleanup_script
echo "rm -fr $batch_file_dir" >> $cleanup_script
echo "rm -fr $batch_file_done_dir" >> $cleanup_script
chmod +x $cleanup_script

# Add these lines just before the final "exit 0":
# docker exec -w /tmp $container_id "ln -s $BUILD_PREFIX/binaries/python-3.10/bin/python3.10 $BUILD_PREFIX/binaries/python-3.10/bin/python3"
# docker exec -w /tmp $container_id "ln -s $BUILD_PREFIX/binaries/python-3.10/bin/python3.10-config $BUILD_PREFIX/binaries/python-3.10/bin/python3-config"

echo "Self-contained image $repo:$self_contained_image_name succeeded"
exit 0
