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

# At least one of the toolchains compilers should have this exact prefix.
TARGET=arm-marvell-linux-gnu
PKG_TARS=$(wildcard ext/libs/* ext/exec/*)
PKGS=$(notdir $(PKG_TARS))
PKGS:=$(PKGS:.tar.gz=)
PKGS:=$(PKGS:.tar.bz2=)
PKG_DESTS=$(PKGS:%=out/%)

all: unpack

precomp/$(TARGET):
	mkdir -p precomp
	tar xf ext/precompiled/$(TARGET).tar.* -C precomp

cc: precomp/$(TARGET)
	ln -s precomp/$(TARGET) cc

$(PKG_DESTS):
	mkdir -p out
	@echo Extracting to $@
	tar mxf ext/*/$(notdir $@).* -C out

unpack: cc $(PKG_DESTS)

clean:
	rm -rf out

realclean: clean
	rm -rf precomp cc
