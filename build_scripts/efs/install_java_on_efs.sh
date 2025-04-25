#!/bin/bash

set -e

build_setup=$1
if [[ "$build_setup" == "" ]] ; then echo "specify setup file with build env variables" >& 2 ; exit 1 ; fi
if [[ ! -e "$build_setup" ]] ; then echo "$build_setup not found"  >& 2 ; exit 1 ; fi
source $build_setup

if [[ "$efs_cache_dir" == "" ]]; then echo "efs_cache_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$build_binaries_dir" == "" ]]; then echo "build_binaries_dir is not defined" >& 2 ; exit 1 ; fi
if [[ "$openjdk_url" == "" ]]; then echo "openjdk_url is not defined" >& 2 ; exit 1 ; fi
if [[ "$JAVA_HOME" == "" ]]; then echo "JAVA_HOME is not defined" >& 2 ; exit 1 ; fi

file=$(basename $openjdk_url)
#file=openjdk-${Java_version}_linux-x64_bin.tar.gz
#url=https://download.java.net/java/GA/jdk${Java_version}/69cfe15208a647278a19ef0990eea691/12/GPL/$file
#wget --no-clobber --no-verbose -P $efs_cache_dir $url
wget --no-clobber --no-verbose -P $efs_cache_dir $openjdk_url
gunzip < $efs_cache_dir/$file | (cd $build_binaries_dir; tar xf -)

# 2023/10 test of binary; ensures handshake btw install & configure 
$JAVA_HOME/bin/java --version

echo " installation succeeded" >& 2
