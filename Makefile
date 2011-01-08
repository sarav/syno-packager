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

# The architecture for which this is being compiled.
# To compile for another target without changing the Makefile, run:
# make ARCH=<arch name>
ARCH=88f5281
ARCHS=$(shell cat arch-target.map | cut -d: -f1)
# 88f6281 compiler is buggy.
ARCHS_BUGGY=
ARCHS_EASY=$(filter-out $(ARCHS_BUGGY), $(ARCHS))

MODELS=$(shell cat arch-target.map | cut -d: -f3 | sed -e 's/S /S/g; s/, / /g')

# Target name to be used for the configure script.
TARGET=$(shell grep ^$(ARCH): arch-target.map | cut -d: -f 2)
# Prefix for CC_PATH
CC_PATH_PREFIX=$(shell grep ^$(ARCH): arch-target.map | cut -d: -f 4)
# Path to the compiler
CC_PATH=precomp/$(ARCH)$(CC_PATH_PREFIX)/$(TARGET)
# Output dir
OUT_DIR=out/$(ARCH)

# Packages that don't follow the GNU ./configure script standard. These
# packages need to have specific out/<arch>/<pkg>/syno.config rule defined.
NONSTD_PKGS=openssl zlib curl

# The main package you are trying to build. Ex: transmission
INSTALL_PKG=transmission

# List of packages that are need to be installed in the device for the main
# package to work. Not all dependencies needed for compilation need to be
# installed in the device. For example, tranmission needs curl and openssl to
# compile, but it doesn't need their libraries to be present in the target
# since transmission is statically compiled.
INSTALL_DEPS=libevent zlib
INSTALL_PREFIX=/

# Generate intermediate variables for use in rules.
PKG_TARS=$(wildcard ext/libs/* ext/exec/*)
PKGS=$(notdir $(PKG_TARS))
PKGS:=$(PKGS:.tgz=)
PKGS:=$(PKGS:.tar.gz=)
PKGS:=$(PKGS:.tar.bz2=)
PKGS_NOVER=$(foreach pkg, $(PKGS), $(shell echo $(pkg) | sed -r -e 's/(.*)-[0-9][0-9.a-zRC]+(-stable|-gpl)?$$/\1/g'))

PKG_DESTS=$(PKGS_NOVER:%=$(OUT_DIR)/%.unpack)
STD_PKGS=$(filter-out $(NONSTD_PKGS), $(PKGS_NOVER))
TEMPROOT=$(PWD)/$(OUT_DIR)/temproot
ROOT=$(PWD)/$(OUT_DIR)/root

INSTALL_TGTS=$(INSTALL_PKG)
# If install dependencies are specified, add them to the install list.
ifneq ($(strip $(INSTALL_DEPS)),)
INSTALL_TGTS+=$(INSTALL_DEPS)
endif
# The rest of the packages are just compiletime dependencies.
SUPPORT_TGTS=$(filter-out $(INSTALL_TGTS), $(PKGS_NOVER))

# Environment variables common to all package compilation
PATH:=$(PWD)/$(CC_PATH)/bin:$(PATH)
PKG_CONFIG_PATH:=$(ROOT)$(INSTALL_PREFIX)/lib/pkgconfig:$(TEMPROOT)$(INSTALL_PREFIX)/lib/pkgconfig
CFLAGS=-I$(PWD)/$(CC_PATH)/include -I$(TEMPROOT)$(INSTALL_PREFIX)/include -I$(ROOT)$(INSTALL_PREFIX)/include
LDFLAGS=-R/usr/local/lib -L$(PWD)/$(CC_PATH)/lib -L$(TEMPROOT)$(INSTALL_PREFIX)/lib -L$(ROOT)$(INSTALL_PREFIX)/lib

all: out check-arch $(INSTALL_PKG)
	@echo $(if $(strip $^),Done,Run \"make help\" to get help info).
	@echo

buildall: $(ARCHS_EASY)

$(ARCHS): out
	@echo Making SPK for arch $@...
	@mkdir -p out/logs
	@nice $(MAKE) ARCH=$@ &> out/logs/$@.log
	@nice $(MAKE) ARCH=$@ spk >> out/logs/$@.log 2>&1
	@echo Done $@.

$(MODELS):
	$(MAKE) $(shell grep $@[,.] arch-target.map | cut -d: -f1)

hash:
	@echo SHA1SUM:
	@cd out && sha1sum *.spk
	@echo MD5SUM:
	@cd out && md5sum *.spk

out:
	@mkdir -p out

check-arch:
	@echo -n "Checking whether architecture $(ARCH) is supported... "
	@grep ^$(ARCH): arch-target.map > /dev/null
	@echo Yes.
	@echo Target: $(TARGET)

archs:
	@echo List of supported architectures:
	@grep ^[^#] arch-target.map | cut -d: -f1,3 --output-delimiter="		"

pkgs:
	@echo List of packages:
	@echo $(PKGS_NOVER)

tests:
	@echo
	@echo SUPPORT_TGTS : $(SUPPORT_TGTS)
	@echo INSTALL_TGTS : $(INSTALL_TGTS)
	@echo PKGS_NOVER : $(PKGS_NOVER)
	@echo STD_PKGS : $(STD_PKGS)
	@echo INSTALL_PREFIX : $(INSTALL_PREFIX)
	@echo CC_PATH_PREFIX : $(CC_PATH_PREFIX)
	@echo CC_PATH : $(CC_PATH)
	@echo LDFLAGS : $(LDFLAGS)
	@echo CFLAGS : $(CFLAGS)
	@echo PKG_CONFIG_PATH : $(PKG_CONFIG_PATH)
	@echo PATH : $(PATH)
	@echo

help:
	@echo
	@echo Help text for architecture $(ARCH):
	@echo make - Compile INSTALL_PKG and place it under out/$(ARCH)/root/
	@echo make ARCH=\<arch\> - Compile INSTALL_PKG for \<arch\> and place it under out/\<arch\>/root/
	@echo make \<packagename\> - Compile package and place it under out/$(ARCH)/temproot
	@echo "			or out/$(ARCH)/root if it's an INSTALL_PKG or INSTALL_DEPS"
	@echo make spk - Create an spk for INSTALL_PKG with the files under out/$(ARCH)/root.
	@echo make clean - Delete all generated files for $(ARCH).
	@echo make realclean - Delete all generated files and uncompressed toolchain.
	@echo

# Dependency declarations.
$(OUT_DIR)/transmission/syno.config: $(OUT_DIR)/openssl/syno.install $(OUT_DIR)/zlib/syno.install $(OUT_DIR)/curl/syno.install $(OUT_DIR)/libevent/syno.install

# Unpack the toolchain and remove conflicting flex.
precomp/$(ARCH):
	grep ^$(ARCH) arch-target.map
	mkdir -p precomp/$(ARCH)
	tar xf ext/precompiled/$(ARCH).* -C precomp/$(ARCH)
	rm -f $(CC_PATH)/bin/flex
	rm -f $(CC_PATH)/bin/flex++

# For each package, create a <outdir>/<package>.unpack target that unpacks the
# source to <outdir>/<package name with version> and creates a symlink called
# <outdir>/<package> that points to it.
$(PKGS_NOVER:%=$(OUT_DIR)/%.unpack):
	@echo $@ ----\> $^
	mkdir -p $(OUT_DIR)
	tar mxf ext/*/$(patsubst %.unpack,%,$(notdir $@))* -C $(OUT_DIR)
	cd $(OUT_DIR)/ && ln -s $(patsubst %.unpack,%,$(notdir $@))* $(patsubst %.unpack,%,$(notdir $@))
	touch $@

# For each standard package, create a <outdir>/<package>/syno.config target.
# This target <prefix>/syno.config depends on <prefix>.unpack and
# precomp/<arch> and handles calling the standard ./configure script with the
# right options.
$(STD_PKGS:%=$(OUT_DIR)/%/syno.config): %/syno.config: %.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--disable-gtk --disable-nls \
			--enable-static --enable-daemon \
			--prefix=$(INSTALL_PREFIX) \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $@

# For each package to be installed, create a <outdir>/<package>/syno.install.
# This target <prefix>/syno.install depends on <prefix>/syno.config and
# handles calling make and make install to install the package in "root".
$(INSTALL_TGTS:%=$(OUT_DIR)/%/syno.install): $(OUT_DIR)/%/syno.install: $(OUT_DIR)/%/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)
	make -C $(dir $@) DESTDIR=$(ROOT) INSTALL_PREFIX=$(ROOT) install
	touch $@

# For each package needed just for compilation, create a
# <outdir>/<package>/syno.install.  This target <prefix>/syno.install depends
# on <prefix>/syno.config and handles calling make and make install to install
# the package in "root".
$(SUPPORT_TGTS:%=$(OUT_DIR)/%/syno.install): $(OUT_DIR)/%/syno.install: $(OUT_DIR)/%/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)
	make -C $(dir $@) DESTDIR=$(TEMPROOT) INSTALL_PREFIX=$(TEMPROOT) install
	touch $@

# For each package, create a easy to use target called <package> that depends
# on <outdir>/<package>/syno.install
$(PKGS_NOVER): %: $(OUT_DIR)/%/syno.install
	@echo $@ ----\> $^

# For each package, create a easy to use <package>.clean target that deletes
# all <outdir>/<package>*
$(PKGS_NOVER:%=%.clean):
	rm -rf $(OUT_DIR)/$(patsubst %.clean,%, $@)*

# Configure non-standard packages. They have the same dependency as standard
# packages, but need different steps for configuring the package.
$(OUT_DIR)/openssl/syno.config: $(OUT_DIR)/openssl.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(OUT_DIR)/openssl && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./Configure gcc --prefix=$(INSTALL_PREFIX) --cross-compile-prefix=$(TARGET)-
	touch $(OUT_DIR)/openssl/syno.config

$(OUT_DIR)/zlib/syno.config: $(OUT_DIR)/zlib.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(OUT_DIR)/zlib && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	CHOST=arm-marvell-linux-gnu \
	./configure --prefix=$(INSTALL_PREFIX)
	touch $(OUT_DIR)/zlib/syno.config

$(OUT_DIR)/curl/syno.config: $(OUT_DIR)/curl.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(OUT_DIR)/curl && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			--with-random=/dev/urandom \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $(OUT_DIR)/curl/syno.config

unpack: precomp/$(ARCH) $(PKG_DESTS)

clean:
	rm -rf $(OUT_DIR)

cleanall:
	rm -rf out

realclean: cleanall
	rm -rf precomp


###########################
#     Packaging rules     #
###########################

SPK_NAME=$(INSTALL_PKG)

SPK_VERSION=$(notdir $(wildcard ext/*/$(INSTALL_PKG)*))
SPK_VERSION:=$(SPK_VERSION:.tgz=)
SPK_VERSION:=$(SPK_VERSION:.tar.gz=)
SPK_VERSION:=$(SPK_VERSION:.tar.bz2=)
SPK_VERSION:=$(SPK_VERSION:$(INSTALL_PKG)%=%)
# The "-" needs to be removed separately.
SPK_VERSION:=$(SPK_VERSION:-%=%)

SPK_ARCH="$(ARCH)"

spk:
	@echo -n "Making spk $(SPK_NAME) version $(SPK_VERSION) for arch $(SPK_ARCH)..."
	@rm -rf $(OUT_DIR)/spk
	@SPK_NAME=$(SPK_NAME) SPK_VERSION=$(SPK_VERSION) SPK_ARCH=$(SPK_ARCH) \
	./src/buildspk.sh
	@echo " Done"
