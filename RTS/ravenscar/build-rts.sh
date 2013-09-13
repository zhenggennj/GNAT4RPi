#!/bin/sh

# Script to build the ravenscar run-time for NXT.
# Access to GNAT and ZFP-support sources are required.

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 gnat-src zfp-src"
  exit 1
fi

gnatsrc=$1
zfpsrc=$2

# You can use ln for debugging.
CP="ln -s"
#CP=cp

objdir=../rts-raven

if [ -d $objdir ]; then
  echo "Object dir $objdir already exists"
  exit 1
fi

# Create directories.
mkdir $objdir
mkdir $objdir/adainclude
mkdir $objdir/adalib

# Build list of sources.
make -f $gnatsrc/Makefile.hie RTS=ravenscar-sfp TARGET=none-elf \
 GNAT_SRC_DIR=$gnatsrc show-sources > ravenscar.src

# Get them.
. ./ravenscar.src

rm -f ravenscar.src

extra_target_pairs="
  s-multip.adb:s-multip-raven-default.adb
  s-textio.adb:s-textio-null.adb"


sedcmd=""
for i in $TARGET_PAIRS $extra_target_pairs; do
  sedcmd="$sedcmd -e s:$i:"
done

# Copy sources.
for f in $LIBGNAT_SOURCES $LIBGNARL_SOURCES $LIBGNAT_NON_COMPILABLE_SOURCES; do
  if [ -f $f ]; then
      # Locally overriden source file.
      $CP $PWD/$f $objdir/adainclude/$f
  else
      # Get from GNAT.
      tf=`echo $f | sed $sedcmd`
      if [ "$f" = "s-secsta.ads" ]; then
          sed -e "/Default_Secondary_Stack_Size : /s/ := .*;/ := 512;/" \
              < $gnatsrc/$tf > $objdir/adainclude/$f
      else
          $CP $gnatsrc/$tf $objdir/adainclude/$f
      fi
  fi
done

# Copy some zfp sources
for f in memory_{set,copy,compare}.{ads,adb}; do
   $CP $zfpsrc/$f $objdir/adainclude/$f
done

arm-eabi-ar rc $objdir/adalib/libgnat.a
arm-eabi-ar rc $objdir/adalib/libgnarl.a

exit 0
