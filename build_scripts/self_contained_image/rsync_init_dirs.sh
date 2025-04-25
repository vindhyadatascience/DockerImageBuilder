#!/bin/sh

# # This script runs inside the image. It rsyncs directories and should be run when making the initial copy of the reference/standard image.
# # Assumes it runs in /tmp

# #mkdir -p /opt/tbio /efs $RSYNC_LOG_DIR
# mkdir -p $RSYNC_LOG_DIR
# mkdir -p /opt/tbio
# #mount -t nfs4 -o ro,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 172.25.135.163:/ /efs
# rsync -av -f"+ */" -f"- *" $SOURCE $DEST > $RSYNC_LOG_DIR/dirs.rsync.log 2> $RSYNC_LOG_DIR/dirs.rsync.err
# #umount /efs

set -x  # Print commands as they execute
echo "SOURCE=$SOURCE"
echo "DEST=$DEST"
echo "RSYNC_LOG_DIR=$RSYNC_LOG_DIR"

mkdir -p $RSYNC_LOG_DIR
mkdir -p /opt/tbio

ls -l $SOURCE 2>&1  # Check if source exists and is accessible
ls -l $DEST 2>&1    # Check if dest exists and is accessible

# rsync -av -f"+ */" -f"- *" $SOURCE $DEST > $RSYNC_LOG_DIR/dirs.rsync.log 2> $RSYNC_LOG_DIR/dirs.rsync.err
rsync -av --include "*/" --exclude "*" "$SOURCE" "$DEST" > $RSYNC_LOG_DIR/dirs.rsync.log 2> $RSYNC_LOG_DIR/dirs.rsync.err