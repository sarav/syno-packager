#!/bin/sh
# Copyright 2010 Saravana Kannan & Antoine Bertin
# <sarav dot devel [ignore this] at gmail period com>
# <diaoulael dot devel [ignore this] at users.sourceforge period net>
#
# This file is part of syno-packager.
#
# syno-packager is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# syno-packager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with syno-packager.  If not, see <http://www.gnu.org/licenses/>.

SPK_NAME=${1:-$SPK_NAME}
SPK_VERSION=${2:-$SPK_VERSION}

if [ "$SPK_NAME" = "" ]; then
	echo "Need at least a package name."
	exit 1
fi

# Get optional meta info for the package
if [ -f src/$SPK_NAME/METAINFO ]; then
	. src/$SPK_NAME/METAINFO
fi

# Set up defaults values
SPK_DESC=${SPK_DESC:-"No description"}
SPK_MAINT=${SPK_MAINT:-"Unknown"}
SPK_RELOADUI=${SPK_RELOADUI:-"yes"}
SPK_VERSION=${SPK_VERSION:-"unknown"}
SPK_URL=${SPK_URL:-""}
SPK_ARCH=${SPK_ARCH:-"noarch"}

# Test the out directory
if [ ! -d out ]; then
	echo "Are you running this from a dir other than the repo root?"
	exit 1
fi

# Common variables
OUT_DIR=$PWD/out
OUT_DIR_ARCH=$OUT_DIR/$SPK_ARCH
SPK_DIR=$OUT_DIR_ARCH/spk
INFO_FILE=$SPK_DIR/INFO
INSTALL_PREFIX=${INSTALL_PREFIX:-"/usr/local"}
SPK_TEST_ARCH=`grep ^$SPK_ARCH arch-target.map | cut -d: -f5`

mkdir -p $SPK_DIR

echo package=\"$SPK_NAME\" > $INFO_FILE
echo version=\"${SPK_VERSION}-${META_VERSION}\" >> $INFO_FILE
echo description=\"$SPK_DESC\" >> $INFO_FILE
echo maintainer=\"$SPK_MAINT\" >> $INFO_FILE
echo arch=\"noarch\" >> $INFO_FILE
echo adminurl=\"$SPK_URL\" >> $INFO_FILE
echo reloadui=\"$SPK_RELOADUI\" >> $INFO_FILE

# Copy scripts and replace the place holders
mkdir -p $SPK_DIR/scripts
cp src/$SPK_NAME/scripts/* $SPK_DIR/scripts
sed -i -e "s/%SPK_ARCH%/$SPK_TEST_ARCH/g" $SPK_DIR/scripts/*

# Copy target and add all stuff from ROOT
mkdir -p $SPK_DIR/target
cp -R src/$SPK_NAME/target/* $SPK_DIR/target
cp -R $OUT_DIR_ARCH/root$INSTALL_PREFIX/* $SPK_DIR/target

# Create the SPK file name
SPK_FILENAME=${SPK_NAME}-${SPK_VERSION}-${META_VERSION}-${SPK_ARCH}.spk

# Make the spk
cd $SPK_DIR/target && tar czf $SPK_DIR/package.tgz *
cd $SPK_DIR && tar cf $OUT_DIR/$SPK_FILENAME INFO package.tgz scripts

