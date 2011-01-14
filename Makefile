# Copyright 2010 Saravana Kannan & Antoine Bertin
# <sarav dot devel [ignore this] at gmail period com>
# <diaoulael [ignore this] at users.sourceforge period net>
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
INSTALL_PREFIX=

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
LDFLAGS=-R/usr/local/$(INSTALL_PKG)/lib -L$(PWD)/$(CC_PATH)/lib -L$(TEMPROOT)$(INSTALL_PREFIX)/lib -L$(ROOT)$(INSTALL_PREFIX)/lib

all: out check-arch $(INSTALL_PKG)
	@echo $(if $(strip $^),Done,Run \"make help\" to get help info).
	@echo

buildall: cleanstatus $(ARCHS_EASY)
	@echo "Building all in background, use 'tail -f out/logs/status.log' to monitor building status in realtime"

$(ARCHS): out
	@echo "Making $(INSTALL_PKG)'s SPK for arch $@..." && \
	mkdir -p out/logs && \
	nice $(MAKE) ARCH=$@ > out/logs/$@.log 2>&1 && \
	nice $(MAKE) ARCH=$@ spk >> out/logs/$@.log 2>&1 && \
	echo "$(INSTALL_PKG)'s SPK for arch $@ built successfully" >> out/logs/status.log || \
	echo "Error while building $(INSTALL_PKG)'s SPK for arch $@, check logs for more details" >> out/logs/status.log &

$(MODELS):
	$(MAKE) $(shell grep $@[,.] arch-target.map | cut -d: -f1)

hash:
	@echo "SHA1SUM:"
	@cd out && sha1sum *.spk
	@echo "MD5SUM:"
	@cd out && md5sum *.spk

out:
	@mkdir -p out

check-arch:
	@echo -n "Checking whether architecture $(ARCH) is supported..."
	@grep ^$(ARCH): arch-target.map > /dev/null
	@echo " yes"
	@echo "Target: $(TARGET)"

archs:
	@echo "List of supported architectures and models:"
	@grep ^[^#] arch-target.map | cut -d: -f1,3 --output-delimiter="		"

models: archs

pkgs:
	@echo "List of packages:"
	@echo "$(PKGS_NOVER)"

tests:
	@echo "Current variables and their values:"
	@echo "SUPPORT_TGTS : $(SUPPORT_TGTS)"
	@echo "INSTALL_TGTS : $(INSTALL_TGTS)"
	@echo "PKGS_NOVER : $(PKGS_NOVER)"
	@echo "STD_PKGS : $(STD_PKGS)"
	@echo "INSTALL_PREFIX : $(INSTALL_PREFIX)"
	@echo "CC_PATH_PREFIX : $(CC_PATH_PREFIX)"
	@echo "CC_PATH : $(CC_PATH)"
	@echo "LDFLAGS : $(LDFLAGS)"
	@echo "CFLAGS : $(CFLAGS)"
	@echo "PKG_CONFIG_PATH : $(PKG_CONFIG_PATH)"
	@echo "PATH : $(PATH)"

help:
	@echo ""
	@echo "usage: make [ARCH=] COMMAND"
	@echo ""
	@echo "The most common COMMANDs are:"
	@echo "  all		Make everything but SPK for ARCH, default command"
	@echo "  buildall	Make everything for all supported archs in background"
	@echo "  hash		Generate MD5 and SHA1 checksums of created SPKs"
	@echo "  out		Create out directory (no need to run this alone)"
	@echo "  check-arch	Check if ARCH is supported"
	@echo "  archs		List all supported archs and models"
	@echo "  models	Same as archs"
	@echo "  pkgs		List all packages"
	@echo "  tests		List current variables and their values"
	@echo "  spk		Make SPK for ARCH"
	@echo "  help		Display this help"
	@echo "  clean		Remove out directory for ARCH"
	@echo "  cleanstatus	Remove status.log (no need to run this alone)"
	@echo "  cleanall	Remove out directory"
	@echo "  realclean	Remove out directory and unpack directory for precomp"
	@echo ""
	@echo "You can also run:"
	@echo "  <arch>	Make everything for specified <arch> in background"
	@echo "  <model>	Make everything for specified <model> in background"
	@echo "  <pkg>		Make a single <pkg> (unpack it if needed)"
	@echo "  <pkg>.clean	Clean a single <pkg>"
	@echo "  <pkg>.unpack	Unpack a single <pkg>"
	@echo ""

# Dependency declarations.
$(OUT_DIR)/transmission/syno.config: $(OUT_DIR)/openssl/syno.install $(OUT_DIR)/zlib/syno.install $(OUT_DIR)/curl/syno.install $(OUT_DIR)/libevent/syno.install
$(OUT_DIR)/umurmur/syno.config: $(OUT_DIR)/libconfig/syno.install $(OUT_DIR)/polarssl/syno.install
$(OUT_DIR)/curl/syno.config: $(OUT_DIR)/openssl/syno.install $(OUT_DIR)/zlib/syno.install
$(OUT_DIR)/openssl/syno.config: $(OUT_DIR)/zlib/syno.install

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
	./Configure gcc --prefix=$(shell if [ "$(INSTALL_PREFIX)" = "" ]; then echo "/"; else echo "$(INSTALL_PREFIX)"; fi) \
			zlib-dynamic --with-zlib-include=$(TEMPROOT)$(INSTALL_PREFIX)/include --with-zlib-lib=$(TEMPROOT)$(INSTALL_PREFIX)/lib \
			--cross-compile-prefix=$(TARGET)-
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
			--with-ssl --with-zlib \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $(OUT_DIR)/curl/syno.config

$(OUT_DIR)/umurmur/syno.config: $(OUT_DIR)/umurmur.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	@sed -i "20c\SSL_LIB:=$(TEMPROOT)$(INSTALL_PREFIX)/lib/libpolarssl.a" $(OUT_DIR)/umurmur/Makefile
	@sed -i "21c\EXTRA_CFLAGS:=-DUSE_POLARSSL $(CFLAGS)" $(OUT_DIR)/umurmur/Makefile
	@sed -i "22c\EXTRA_LDFLAGS:=-lpolarssl $(LDFLAGS)" $(OUT_DIR)/umurmur/Makefile
	@sed -i "1i\CC:=$(TARGET)-gcc" $(OUT_DIR)/umurmur/Makefile
	@sed -i "/all: umurmurd/a\\\ninstall:\n\tcp umurmurd \$$(INSTALL_PREFIX)$(INSTALL_PREFIX)/bin/" $(OUT_DIR)/umurmur/Makefile
	@sed -i "1i\CFLAGS:=$(CFLAGS)" $(OUT_DIR)/umurmur/google/protobuf-c/Makefile
	@sed -i "1i\LDFLAGS:=$(LDFLAGS)" $(OUT_DIR)/umurmur/google/protobuf-c/Makefile
	@sed -i "1i\CC:=$(TARGET)-gcc" $(OUT_DIR)/umurmur/google/protobuf-c/Makefile
	@sed -i "1i\AR:=$(TARGET)-ar" $(OUT_DIR)/umurmur/google/protobuf-c/Makefile
	touch $(OUT_DIR)/umurmur/syno.config

$(OUT_DIR)/polarssl/syno.config: $(OUT_DIR)/polarssl.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	@sed -i "2i\CC=$(TARGET)-gcc" $(OUT_DIR)/polarssl/Makefile
	@sed -i "2i\CINSTALL_PREFIX=$(INSTALL_PREFIX)" $(OUT_DIR)/polarssl/Makefile
	@sed -ri 's/\$$\(DESTDIR\)/$$(DESTDIR)$$(CINSTALL_PREFIX)/g' $(OUT_DIR)/polarssl/Makefile
	@sed -i "/cd programs/d" $(OUT_DIR)/polarssl/Makefile
	@sed -i "/cd tests/d" $(OUT_DIR)/polarssl/Makefile
	@sed -i "/\.SILENT:/d" $(OUT_DIR)/polarssl/Makefile
	@sed -i "/\.SILENT:/d" $(OUT_DIR)/polarssl/library/Makefile
	@sed -i "s/ -Wdeclaration-after-statement//g" $(OUT_DIR)/polarssl/library/Makefile
	@sed -i "4i\CC=$(TARGET)-gcc" $(OUT_DIR)/polarssl/library/Makefile
	@sed -i "/^CFLAGS/a \CFLAGS+=$(CFLAGS)" $(OUT_DIR)/polarssl/library/Makefile
	@sed -i "s/^\tar /\t$(TARGET)-ar /" $(OUT_DIR)/polarssl/library/Makefile
	@sed -i "s/^\tranlib /\t$(TARGET)-ranlib /" $(OUT_DIR)/polarssl/library/Makefile
	touch $(OUT_DIR)/polarssl/syno.config

unpack: precomp/$(ARCH) $(PKG_DESTS)

clean:
	rm -rf $(OUT_DIR)

cleanstatus:
	rm -f out/logs/status.log

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
	@INSTALL_PREFIX=$(INSTALL_PREFIX) SPK_NAME=$(SPK_NAME) SPK_VERSION=$(SPK_VERSION) SPK_ARCH=$(SPK_ARCH) \
	./src/buildspk.sh
	@echo " Done"
