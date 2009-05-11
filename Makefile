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

# Packages that don't follow the GNU ./configure script standard. These
# packages need to have specific out/<pkg>/syno.config rule defined.
NONSTD_PKGS=openssl

# List of packages that need to be installed in the target. For example, curl
# and openssl don't need to be installed for transmission since transmission is
# statically compiled. So when compiling to install transmission, one would
# omit curl and openssl from this list.
INSTALL_PKGS=transmission

# Generate package names from ext/libs/* and ext/exec/*
PKG_TARS=$(wildcard ext/libs/* ext/exec/*)
PKGS=$(notdir $(PKG_TARS))
PKGS:=$(PKGS:.tar.gz=)
PKGS:=$(PKGS:.tar.bz2=)
PKGS_NOVER=$(foreach pkg, $(PKGS), $(shell echo $(pkg) | sed -r -e 's/(.*)-[0-9][0-9.a-zRC]+$$/\1/g'))

PKG_DESTS=$(PKGS_NOVER:%=out/%.unpack)
STD_PKGS=$(filter-out $(NONSTD_PKGS), $(PKGS_NOVER))
TEMPROOT=$(PWD)/out/temproot
ROOT=$(PWD)/out/root/usr/local
INSTALL_TGTS=$(INSTALL_PKGS:%=out/%/syno.config)

# Environment variables common to all package compilation
PATH:=$(PWD)/cc/bin:$(PATH)
CFLAGS=-I$(PWD)/cc/include -I$(TEMPROOT)/include -I$(ROOT)/include
LDFLAGS=-L$(PWD)/cc/lib -L$(TEMPROOT)/lib -L$(ROOT)/lib

all: transmission

# Dependency declarations.
out/transmission/syno.config: out/curl/syno.install out/openssl/syno.install

# Unpack the toolchain
precomp/$(TARGET):
	mkdir -p precomp
	tar xf ext/precompiled/$(TARGET).tar.* -C precomp

cc: precomp/$(TARGET)
	ln -s precomp/$(TARGET) cc

$(PKGS_NOVER:%=out/%.unpack):
	@echo $@ ----\> $^
	mkdir -p out
	tar mxf ext/*/$(patsubst %.unpack,%,$(notdir $@))* -C out
	cd out/ && ln -s $(patsubst %.unpack,%,$(notdir $@))* $(patsubst %.unpack,%,$(notdir $@))
	touch $@

$(STD_PKGS:%=out/%/syno.config): %/syno.config: %.unpack cc
	@echo $@ ----\> $^
	cd $(dir $@) && \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--disable-gtk --disable-nls \
			--prefix=$(if $(filter $@, $(INSTALL_TGTS)),$(ROOT),$(TEMPROOT)) \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $@

$(PKGS_NOVER:%=out/%/syno.install): out/%/syno.install: out/%/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)
	make -C $(dir $@) install
	touch $@

$(PKGS_NOVER): %: out/%/syno.install
	@echo $@ ----\> $^

$(PKGS_NOVER:%=%.clean):
	rm -rf out/$(patsubst %.clean,%, $@)*

out/openssl/syno.config: out/openssl.unpack cc
	@echo $@ ----\> $^
	cd out/openssl && \
	./Configure.syno linux-elf-armle --prefix=$(if $(filter $@, $(INSTALL_TGTS)),$(ROOT),$(TEMPROOT)) --cc=$(TARGET)-gcc
	touch out/openssl/syno.config

unpack: cc $(PKG_DESTS)

clean:
	rm -rf out

realclean: clean
	rm -rf precomp cc
