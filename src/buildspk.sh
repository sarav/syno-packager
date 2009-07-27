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

if [ "$1" != "" ]; then
	SPK_NAME=$1
fi
if [ "$2" != "" ]; then
	SPK_VERSION=$2
fi
if [ "$3" != "" ]; then
	SPK_DESC=$3
fi
if [ "$4" != "" ]; then
	SPK_MAINT=$4
fi
if [ "$5" != "" ]; then
	SPK_ARCH=$5
fi
if [ "$6" != "" ]; then
	SPK_RELOADUI=$6
fi

if [ "$SPK_NAME" = "" ]; then
	echo Need at least a package name.
	exit 1
fi

if [ "$SPK_VERSION" = "" ]; then
	SPK_VERSION=unknown
fi
if [ "$SPK_DESC" = "" ]; then
	SPK_DESC="No description"
fi
if [ "$SPK_MAINT" = "" ]; then
	SPK_MAINT=Unknown
fi
if [ "$SPK_ARCH" = "" ]; then
	SPK_ARCH=noarch
fi
if [ "$SPK_RELOADUI" = "" ]; then
	SPK_RELOADUI=yes
fi

if [ ! -d out ]; then
	echo Are you running this from a dir other than the repo root?
	exit 1
fi

OUT_DIR=out/$SPK_ARCH
SPK_DIR=$OUT_DIR/spk
INFO_FILE=$SPK_DIR/INFO

mkdir -p $SPK_DIR

echo package=\"$SPK_NAME\" > $INFO_FILE
echo version=\"$SPK_VERSION\" >> $INFO_FILE
echo description=\"$SPK_DESC\" >> $INFO_FILE
echo maintainer=\"$SPK_MAINT\" >> $INFO_FILE
echo arch=\"$SPK_ARCH\" >> $INFO_FILE
echo reloadui=\"$SPK_RELOADUI\" >> $INFO_FILE

mkdir -p $SPK_DIR/scripts
cp src/$SPK_NAME/spk/* $SPK_DIR/scripts

# Search and replace the place holders in the scripts.
sed -i -e "s/%SPK_ARCH%/$SPK_ARCH/g" $SPK_DIR/scripts/*

if [ -d src/$SPK_NAME/extra ]; then
	rm -rf $OUT_DIR/root/extra
	cp -r src/$SPK_NAME/extra $OUT_DIR/root/extra
fi

cd $OUT_DIR/root && tar czf ../../../$SPK_DIR/package.tgz *
cd ../../../$SPK_DIR
rm -f ../../$SPK_NAME-$SPK_VERSION-$SPK_ARCH.spk
tar cf ../../$SPK_NAME-$SPK_VERSION-$SPK_ARCH.spk *

