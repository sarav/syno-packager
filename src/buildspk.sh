#!/bin/sh
# Copyright 2009 Saravana Kannan
# <sarav dot devel [ignore this] at gmail period com>
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
	echo Need at least a package name.
	exit 1
fi

# Get optional meta info for the package.
if [ -f src/$SPK_NAME/METAINFO ]; then
	. src/$SPK_NAME/METAINFO
fi
# Fix up values obtained from METAINFO
meta_version=${meta_version:+-$meta_version}

# Set up defaults values.
SPK_VERSION=${SPK_VERSION:-"unknown"}
SPK_DESC=${SPK_DESC:-"No description"}
SPK_MAINT=${SPK_MAINT:-"Unknown"}
SPK_ARCH=${SPK_ARCH:-"noarch"}
SPK_RELOADUI=${SPK_RELOADUI:-"yes"}

if [ ! -d out ]; then
	echo Are you running this from a dir other than the repo root?
	exit 1
fi

OUT_DIR=out/$SPK_ARCH
SPK_DIR=$OUT_DIR/spk
INFO_FILE=$SPK_DIR/INFO

mkdir -p $SPK_DIR

echo package=\"$SPK_NAME\" > $INFO_FILE
echo version=\"${SPK_VERSION}${meta_version}\" >> $INFO_FILE
echo description=\"$SPK_DESC\" >> $INFO_FILE
echo maintainer=\"$SPK_MAINT\" >> $INFO_FILE
echo arch=\"noarch\" >> $INFO_FILE
echo reloadui=\"$SPK_RELOADUI\" >> $INFO_FILE

mkdir -p $SPK_DIR/scripts
cp src/$SPK_NAME/spk/* $SPK_DIR/scripts

# Search and replace the place holders in the scripts.
sed -i -e "s/%SPK_ARCH%/$SPK_ARCH/g" $SPK_DIR/scripts/*

if [ -d src/$SPK_NAME/extra ]; then
	rm -rf $OUT_DIR/root/extra
	cp -r src/$SPK_NAME/extra $OUT_DIR/root/extra
fi

SPK_FILENAME=${SPK_NAME}-${SPK_VERSION}-${SPK_ARCH}${meta_version}.spk

cd $OUT_DIR/root && tar czf ../../../$SPK_DIR/package.tgz *
cd ../../../$SPK_DIR
rm -f ../../$SPK_FILENAME
tar cf ../../$SPK_FILENAME *

