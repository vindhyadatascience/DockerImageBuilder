#!/bin/sh

# 2023/01/04: final sync should be:
# rsync --ignore-existing -avz /efs/domino_202212 /opt/tbio/

# This script runs inside the image. 
# It rsyncs everything except existing files (symbolic links, files with commas), so it should be run after all batches of regular files.
# Assumes it runs in /tmp.

mkdir -p $RSYNC_LOG_DIR
#mount -t nfs4 -o ro,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 172.25.135.163:/ /efs
rsync --ignore-existing -avz $SOURCE $DEST > $RSYNC_LOG_DIR/final.rsync.log 2> $RSYNC_LOG_DIR/final.rsync.err

#rm -fr $DEST/transfer
#umount /efs
