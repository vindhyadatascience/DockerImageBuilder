#!/bin/sh

# # This script runs inside the image for each batch of files to rsync.
# # The input file contains a list of files, without the path.

# file_list=$1
# mkdir -p $RSYNC_LOG_DIR
# #mount -t nfs4 -o ro,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 172.25.135.163:/ /efs
# rsync -avz --files-from=$file_list $SOURCE $DEST > $RSYNC_LOG_DIR/$file_list.rsync.log 2> $RSYNC_LOG_DIR/$file_list.rsync.err
# #umount /efs

set -x

file_list="/tmp/$1"  # Use absolute path
mkdir -p $DEST
mkdir -p $RSYNC_LOG_DIR
rsync -avz --files-from="$file_list" "$SOURCE" "$DEST" #> "$RSYNC_LOG_DIR/$1.rsync.log" 2> "$RSYNC_LOG_DIR/$1.rsync.err"