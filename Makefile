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

# The main package you are trying to build. Ex: transmission
INSTALL_PKG=transmission

# List of packages that are need to be installed in the device for the main
# package to work. Not all dependencies needed for compilation need to be
# installed in the device. For example, tranmission needs curl and openssl to
# compile, but it doesn't need their libraries to be present in the target
# since transmission is statically compiled.
INSTALL_DEPS=
INSTALL_PREFIX=/usr/local

# Generate intermediate variables for use in rules.
PKG_TARS=$(wildcard ext/libs/* ext/exec/*)
PKGS=$(notdir $(PKG_TARS))
PKGS:=$(PKGS:.tar.gz=)
PKGS:=$(PKGS:.tar.bz2=)
PKGS_NOVER=$(foreach pkg, $(PKGS), $(shell echo $(pkg) | sed -r -e 's/(.*)-[0-9][0-9.a-zRC]+$$/\1/g'))

PKG_DESTS=$(PKGS_NOVER:%=out/%.unpack)
STD_PKGS=$(filter-out $(NONSTD_PKGS), $(PKGS_NOVER))
TEMPROOT=$(PWD)/out/temproot
ROOT=$(PWD)/out/root$(INSTALL_PREFIX)
INSTALL_TGTS=$(INSTALL_PKG:%=out/%/syno.config)
ifneq ($(strip $(INSTALL_DEPS)),)
INSTALL_TGTS+=$(INSTALL_DEPS:%=out/%/syno.config)
endif

# Environment variables common to all package compilation
PATH:=$(PWD)/cc/bin:$(PATH)
CFLAGS=-I$(PWD)/cc/include -I$(TEMPROOT)/include -I$(ROOT)/include
LDFLAGS=-L$(PWD)/cc/lib -L$(TEMPROOT)/lib -L$(ROOT)/lib

all: $(INSTALL_PKG)
	@echo $(if $(strip $^),Done,Run \"make help\" to get help info).
	@echo

help:
	@echo make - Compile INSTALL_PKG and place it under out/root/
	@echo make \<packagename\> - Compile package and place it under out/temproot
	@echo "			or out/root if it's an INSTALL_PKG or INSTALL_DEPS"
	@echo make spk - Create an spk for INSTALL_PKG with the files under out/root.
	@echo make clean - Delete all generated files.
	@echo make realclean - Delete all generated files and uncompressed toolchain.
	@echo

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


###########################
#     Packaging rules     #
###########################

SPK_NAME=$(INSTALL_PKG)

SPK_VERSION=$(notdir $(wildcard ext/*/$(INSTALL_PKG)*))
SPK_VERSION:=$(SPK_VERSION:.tar.gz=)
SPK_VERSION:=$(SPK_VERSION:.tar.bz2=)
SPK_VERSION:=$(SPK_VERSION:$(INSTALL_PKG)%=%)
# The "-" needs to be removed separately.
SPK_VERSION:=$(SPK_VERSION:-%=%)

SPK_DESC=
SPK_MAINT=
SPK_ARCH=
SPK_RELOADUI=

spk:
	rm -rf out/spk
	@SPK_NAME=$(SPK_NAME) SPK_VERSION=$(SPK_VERSION) SPK_DESC=$(SPK_DESC) \
	SPK_MAINT=$(SPK_MAINT) SPK_ARCH=$(SPK_ARCH) \
	SPK_RELOADUI=$(SPK_RELOADUI) \
	./scripts/buildspk.sh
