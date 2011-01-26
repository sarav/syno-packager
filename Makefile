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

######################
# User can edit this #
######################
#
# Packaging rules
ARCH=88f5281
INSTALL_PKG=SABnzbd
NONSTD_PKGS_CONFIGURE=SABnzbd Python zlib ncurses readline bzip2 openssl libffi tcl Cheetah Markdown pyOpenSSL psmisc sysvinit coreutils util-linux-ng
NONSTD_PKGS_INSTALL=SABnzbd Python bzip2 tcl Cheetah Markdown pyOpenSSL psmisc sysvinit util-linux-ng coreutils
INSTALL_DEPS=zlib openssl sqlite par2cmdline

# Prefix (optional, can be blank)
INSTALL_PREFIX=

######################################
# User shouldn't edit anything below #
# except non-standard rules          #
######################################
#
# Using arch-target.map to define some variables
ARCHS=$(shell cat arch-target.map | cut -d: -f1)
MODELS=$(shell cat arch-target.map | cut -d: -f3 | sed -e 's/S /S/g; s/, / /g')
TARGET=$(shell grep ^$(ARCH): arch-target.map | cut -d: -f 2)
CC_PATH=precomp/$(ARCH)$(shell grep ^$(ARCH): arch-target.map | cut -d: -f 4)/$(TARGET)

# List available packages in ext/libs and ext/exec directories
AVAILABLE_PKGS=$(strip $(foreach pkg, \
	$(notdir $(wildcard ext/libs/*.tgz ext/libs/*.tar.gz ext/libs/*.tar.bz2 ext/exec/*.tgz ext/exec/*.tar.gz ext/exec/*.tar.bz2)), \
	$(shell echo $(pkg) | sed -r -e 's/^(\w*(-linux)?(-ng)?)(-autoconf)?-?[0-9][0-9.a-zRC]+(-stable|-gpl|-src)?\.(tgz|tar\.gz|tar\.bz2)$$/\1/g')) \
)

# Extra rules for very non-standard packages (no binaries, no source code)
EXTRA_PKGS=$(filter-out $(AVAILABLE_PKGS), $(strip $(INSTALL_PKG) $(INSTALL_DEPS)))

# Sort package names in variables for further use depending of their "standardness"
STD_PKGS_CONFIGURE=$(filter-out $(NONSTD_PKGS_CONFIGURE), $(AVAILABLE_PKGS))
STD_PKGS_INSTALL_ROOT=$(filter $(INSTALL_DEPS), $(filter-out $(NONSTD_PKGS_INSTALL), $(AVAILABLE_PKGS)))
STD_PKGS_INSTALL_TEMPROOT=$(filter-out $(strip $(STD_PKGS_INSTALL_ROOT) $(NONSTD_PKGS_INSTALL)), $(AVAILABLE_PKGS))

# Declaring directories
OUT_DIR=out/$(ARCH)
EXT_DIR=$(PWD)/ext
CUR_DIR=$(PWD)
TEMPROOT=$(PWD)/$(OUT_DIR)/temproot
ROOT=$(PWD)/$(OUT_DIR)/root

# Environment variables common to all package compilation
PATH:=$(PWD)/$(CC_PATH)/bin:$(PATH)
PKG_CONFIG_PATH:=$(ROOT)$(INSTALL_PREFIX)/lib/pkgconfig:$(TEMPROOT)$(INSTALL_PREFIX)/lib/pkgconfig
CFLAGS=-I$(PWD)/$(CC_PATH)/include -I$(TEMPROOT)$(INSTALL_PREFIX)/include -I$(ROOT)$(INSTALL_PREFIX)/include
CPPFLAGS=$(CFLAGS)
LDFLAGS=-R/usr/local/$(INSTALL_PKG)/lib -L$(PWD)/$(CC_PATH)/lib -L$(TEMPROOT)$(INSTALL_PREFIX)/lib -L$(ROOT)$(INSTALL_PREFIX)/lib

# Variables used to check for bugged config.h and syno.h
SYNO_H=precomp/$(ARCH)$(shell grep ^$(ARCH): arch-target.map | cut -d: -f 4)/$(TARGET)/include/linux/syno.h
CONFIG_H=precomp/$(ARCH)$(shell grep ^$(ARCH): arch-target.map | cut -d: -f 4)/$(TARGET)/include/linux/config.h


##################
# Standard rules #
##################
#
all: out check-arch $(INSTALL_PKG)
	@echo $(if $(strip $^),Done,Run \"make help\" to get help info).
	@echo

buildall: cleanstatus $(ARCHS)
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
	@echo "$(AVAILABLE_PKGS)"

tests:
	@echo "Current variables and their values:"
	@echo "Packages (user defined):"
	@echo "	INSTALL_PKG			$(INSTALL_PKG)"
	@echo "	NONSTD_PKGS_CONFIGURE		$(NONSTD_PKGS_CONFIGURE)"
	@echo "	NONSTD_PKGS_INSTALL		$(NONSTD_PKGS_INSTALL)"
	@echo "	INSTALL_DEPS			$(INSTALL_DEPS)"
	@echo ""
	@echo "Packages (auto-detected):"
	@echo "	AVAILABLE_PKGS			$(AVAILABLE_PKGS)"
	@echo "	EXTRA_PKGS			$(EXTRA_PKGS)"
	@echo "	STD_PKGS_CONFIGURE		$(STD_PKGS_CONFIGURE)"
	@echo "	STD_PKGS_INSTALL_ROOT		$(STD_PKGS_INSTALL_ROOT)"
	@echo "	STD_PKGS_INSTALL_TEMPROOT	$(STD_PKGS_INSTALL_TEMPROOT)"
	@echo ""
	@echo "Directories:"
	@echo "	TEMPROOT			$(TEMPROOT)"
	@echo "	ROOT				$(ROOT)"
	@echo "	EXT_DIR				$(EXT_DIR)"
	@echo "	CUR_DIR				$(CUR_DIR)"
	@echo "	OUT_DIR				$(OUT_DIR)"
	@echo ""
	@echo "Compilation:"
	@echo "	PATH				$(PATH)"
	@echo "	PKG_CONFIG_PATH			$(PKG_CONFIG_PATH)"
	@echo "	CFLAGS				$(CFLAGS)"
	@echo "	CPPFLAGS			$(CPPFLAGS)"
	@echo "	LDFLAGS				$(LDFLAGS)"

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
	@echo "  <arch>			Make everything for specified <arch> in background"
	@echo "  <model>			Make everything for specified <model> in background"
	@echo "  <pkg>				Make <pkg>"
	@echo "  <pkg>.clean			Clean <pkg>"
	@echo "  out/<arch>/<pkg>.unpack	Unpack <pkg> for <arch>"
	@echo "  out/<arch>/<pkg>/syno.config	Configure <pkg> for <arch>"
	@echo "  out/<arch>/<pkg>/syno.install	Make and install <pkg> for <arch>"
	@echo ""

unpack: precomp/$(ARCH) $(PKG_DESTS)

clean:
	rm -rf $(OUT_DIR)

cleanstatus:
	rm -f out/logs/status.log

cleanall:
	rm -rf out

realclean: cleanall
	rm -rf precomp


##################
# Specific rules #
##################
#
# Unpack the toolchain, remove conflicting flex and correct buggy config.h on some arch.
precomp/$(ARCH):
	grep ^$(ARCH) arch-target.map
	mkdir -p precomp/$(ARCH)
	tar xf ext/precompiled/$(ARCH).* -C precomp/$(ARCH)
	rm -f $(CC_PATH)/bin/flex
	rm -f $(CC_PATH)/bin/flex++
	@[ -f $(SYNO_H) ] && [ -f $(CONFIG_H) ] && cat $(SYNO_H) | grep -q '[0-9]define[0-9]' && sed -i "s|^#include|//#include|" $(CONFIG_H) \
	&& echo "config.h has beed corrected" || echo "config.h is not buggy"

# For each package, create a out/<arch>/<pkg>.unpack target that unpacks the
# source to out/<arch>/<versionned pkg> and creates a symlink called
# out/<arch>/<pkg> that points to it.
$(AVAILABLE_PKGS:%=$(OUT_DIR)/%.unpack):
	@echo $@ ----\> $^
	mkdir -p $(OUT_DIR)
	tar mxf ext/*/$(patsubst %.unpack,%,$(notdir $@))*.t* -C $(OUT_DIR)
	cd $(OUT_DIR)/ && ln -s $(patsubst %.unpack,%,$(notdir $@))* $(patsubst %.unpack,%,$(notdir $@))
	touch $@

# For each standard package, create a out/<arch>/<pkg>/syno.config target.
# This target <prefix>/syno.config depends on <prefix>.unpack and
# precomp/<arch> and handles calling the standard ./configure script with the
# right options.
$(STD_PKGS_CONFIGURE:%=$(OUT_DIR)/%/syno.config): %/syno.config: %.unpack precomp/$(ARCH)
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

# For each package to be installed, create a out/<arch>/<pkg>/syno.install.
# This target <prefix>/syno.install depends on <prefix>/syno.config and
# handles calling make and make install to install the package in "root".
$(STD_PKGS_INSTALL_ROOT:%=$(OUT_DIR)/%/syno.install): $(OUT_DIR)/%/syno.install: $(OUT_DIR)/%/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)
	make -C $(dir $@) DESTDIR=$(ROOT) INSTALL_PREFIX=$(ROOT) install
	touch $@

# For each package needed just for compilation, create a
# out/<arch>/<pkg>/syno.install. This target <prefix>/syno.install depends
# on <prefix>/syno.config and handles calling make and make install to install
# the package in "temproot".
$(STD_PKGS_INSTALL_TEMPROOT:%=$(OUT_DIR)/%/syno.install): $(OUT_DIR)/%/syno.install: $(OUT_DIR)/%/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)
	make -C $(dir $@) DESTDIR=$(TEMPROOT) INSTALL_PREFIX=$(TEMPROOT) install
	touch $@

# For each package, create a easy to use target called <pkg> that depends
# on out/<arch>/<package>/syno.install
$(AVAILABLE_PKGS): %: $(OUT_DIR)/%/syno.install
	@echo $@ ----\> $^

# For each package, create a easy to use <pkg>.clean target that deletes
# all out/<arch>/<pkg>*
$(AVAILABLE_PKGS:%=%.clean):
	rm -rf $(OUT_DIR)/$(patsubst %.clean,%, $@)*

$(EXTRA_PKGS): %: $(OUT_DIR)/%.install


##############################
# User defined, non-standard #
# configure rules            #
##############################
#
$(OUT_DIR)/transmission/syno.config: $(OUT_DIR)/openssl/syno.install $(OUT_DIR)/zlib/syno.install $(OUT_DIR)/curl/syno.install $(OUT_DIR)/libevent/syno.install

$(OUT_DIR)/coreutils/syno.config: $(OUT_DIR)/coreutils.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $@

$(OUT_DIR)/openssl/syno.config: $(OUT_DIR)/zlib/syno.install $(OUT_DIR)/openssl.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(OUT_DIR)/openssl && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./Configure --prefix=$(shell if [ "$(INSTALL_PREFIX)" = "" ]; then echo "/"; else echo "$(INSTALL_PREFIX)"; fi) \
			zlib-dynamic --with-zlib-include="$(ROOT)$(INSTALL_PREFIX)/include -I$(TEMPROOT)$(INSTALL_PREFIX)/include" --with-zlib-lib="$(ROOT)$(INSTALL_PREFIX)/lib -L$(TEMPROOT)$(INSTALL_PREFIX)/lib" \
			shared --cross-compile-prefix=$(TARGET)- "syno:gcc:-O3::(unknown)::-ldl:BN_LLONG:::::::::::::::dlfcn:linux-shared:-fPIC::.so.\\\$$\(SHLIB_MAJOR\).\\\$$\(SHLIB_MINOR\):"
	touch $(OUT_DIR)/openssl/syno.config

$(OUT_DIR)/zlib/syno.config: $(OUT_DIR)/zlib.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(OUT_DIR)/zlib && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	CHOST=$(TARGET) \
	./configure --prefix=$(INSTALL_PREFIX) --static --shared
	touch $(OUT_DIR)/zlib/syno.config

$(OUT_DIR)/curl/syno.config: $(OUT_DIR)/zlib/syno.install $(OUT_DIR)/openssl/syno.install  $(OUT_DIR)/curl.unpack precomp/$(ARCH)
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

$(OUT_DIR)/umurmur/syno.config: $(OUT_DIR)/libconfig/syno.install $(OUT_DIR)/polarssl/syno.install $(OUT_DIR)/umurmur.unpack precomp/$(ARCH)
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

$(OUT_DIR)/Python/host.install: $(OUT_DIR)/ncurses/syno.install $(OUT_DIR)/readline/syno.install $(OUT_DIR)/zlib/syno.install $(OUT_DIR)/bzip2/syno.install $(OUT_DIR)/tcl/syno.install $(OUT_DIR)/sqlite/syno.install $(OUT_DIR)/openssl/syno.install $(OUT_DIR)/Python.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure
	make -C $(dir $@)
	mv $(dir $@)python $(dir $@)hostpython
	mv $(dir $@)Parser/pgen $(dir $@)Parser/hostpgen
	touch $@

$(OUT_DIR)/Python/syno.config: $(OUT_DIR)/Python/host.install
	@echo $@ ----\> $^
	patch -d $(dir $@) -p 1 -i $(EXT_DIR)/others/Python-2.6.6-xcompile.patch
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			--with-cxx-main=$(TARGET)-g++ \
			CFLAGS="-DPATH_MAX=4096 -mfloat-abi=soft $(CFLAGS)" LDFLAGS="$(LDFLAGS)" CPPFLAGS="$(CPPFLAGS)"
	touch $@

$(OUT_DIR)/ncurses/syno.config: $(OUT_DIR)/ncurses.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) --enable-overwrite \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $@

$(OUT_DIR)/readline/syno.config: $(OUT_DIR)/ncurses/syno.install $(OUT_DIR)/readline.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $@

$(OUT_DIR)/libffi/syno.config: $(OUT_DIR)/libffi.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			CFLAGS="-mfloat-abi=soft $(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $@

$(OUT_DIR)/bzip2/syno.config: $(OUT_DIR)/bzip2.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	touch $@

$(OUT_DIR)/Cheetah/syno.config: $(OUT_DIR)/Cheetah.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	touch $@

$(OUT_DIR)/pyOpenSSL/syno.config: $(OUT_DIR)/pyOpenSSL.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	touch $@

$(OUT_DIR)/Markdown/syno.config: $(OUT_DIR)/Markdown.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	touch $@

$(OUT_DIR)/SABnzbd/syno.config: $(OUT_DIR)/par2cmdline/syno.install $(OUT_DIR)/pyOpenSSL/syno.install $(OUT_DIR)/Cheetah/syno.install $(OUT_DIR)/SABnzbd.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	touch $@

$(OUT_DIR)/tcl/syno.config: $(OUT_DIR)/tcl.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@)unix && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	ac_cv_func_strtod=yes \
	tcl_cv_strtod_buggy=1 \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	@sed -i "s|\./\$${TCL_EXE}|\$$\{TCL_EXE\}|" $(OUT_DIR)/tcl/unix/Makefile
	touch $@

$(OUT_DIR)/psmisc/syno.config: $(OUT_DIR)/psmisc.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	ac_cv_func_malloc_0_nonnull=yes \
	ac_cv_func_realloc_0_nonnull=yes \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"
	touch $@

$(OUT_DIR)/sysvinit/syno.config: $(OUT_DIR)/sysvinit.unpack precomp/$(ARCH)
	@echo $@ ----\> $^
	touch $@

$(OUT_DIR)/util-linux-ng/syno.config: $(OUT_DIR)/ncurses/syno.install $(OUT_DIR)/util-linux-ng.unpack precomp/$(ARCH)
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


##############################
# User defined, non-standard #
# install rules              #
##############################
#
$(OUT_DIR)/CouchPotato.install:
	@echo $@ ----\> $^
	mkdir -p $(ROOT)
	cd $(ROOT) && git clone https://github.com/RuudBurger/CouchPotato.git
	touch $@

$(OUT_DIR)/SickBeard.install:
	@echo $@ ----\> $^
	mkdir -p $(ROOT)
	cd $(ROOT) && git clone https://github.com/midgetspy/Sick-Beard.git
	mv $(ROOT)/Sick-Beard $(ROOT)/SickBeard
	touch $@

$(OUT_DIR)/SABnzbd/syno.install: $(OUT_DIR)/util-linux-ng/syno.install $(OUT_DIR)/coreutils/syno.install $(OUT_DIR)/SABnzbd/syno.clean $(OUT_DIR)/SABnzbd/syno.config 
	@echo $@ ----\> $^
	mkdir -p $(ROOT)/SABnzbd
	cp -Rf $(OUT_DIR)/SABnzbd/* $(ROOT)/SABnzbd
	rm -f $(ROOT)/SABnzbd/syno.config
	touch $@

$(OUT_DIR)/SABnzbd/syno.clean: $(OUT_DIR)/Python/syno.install $(OUT_DIR)/SABnzbd/syno.config
	@echo $@ ----\> $^
	rm -f $(ROOT)/bin/python2.6
	$(TARGET)-strip $(ROOT)/bin/python
	$(TARGET)-strip $(ROOT)/bin/openssl
	$(TARGET)-strip $(ROOT)/bin/nice
	$(TARGET)-strip $(ROOT)/bin/ionice
	$(TARGET)-strip $(ROOT)/bin/par2
	rm -f $(ROOT)/bin/2to3
	rm -f $(ROOT)/bin/cheetah
	rm -f $(ROOT)/bin/cheetah-analyze
	rm -f $(ROOT)/bin/cheetah-compile
	rm -f $(ROOT)/bin/c_rehash
	rm -f $(ROOT)/bin/idle
	rm -f $(ROOT)/bin/markdown
	rm -f $(ROOT)/bin/pydoc
	rm -f $(ROOT)/bin/python2.6-config
	rm -f $(ROOT)/bin/python-config
	rm -f $(ROOT)/bin/smtpd.py
	rm -f $(ROOT)/bin/sqlite3
	rm -f $(ROOT)/bin/par2create
	rm -f $(ROOT)/bin/par2verify
	rm -f $(ROOT)/bin/par2repair
	cd $(ROOT)/bin/ && ln -s par2 par2create
	cd $(ROOT)/bin/ && ln -s par2 par2verify
	cd $(ROOT)/bin/ && ln -s par2 par2repair
	rm -rf $(ROOT)/ssl
	rm -rf $(ROOT)/include
	rm -rf $(ROOT)/share
	rm -f $(ROOT)/lib/*.a
	rm -rf $(ROOT)/lib/python2.6/test
	rm -rf $(ROOT)/lib/python2.6/config
	rm -f `find $(ROOT)/lib/python2.6/ -name "*.pyo"`
	rm -f `find $(ROOT)/lib/python2.6/ -name "*.py"`
	touch $@

$(OUT_DIR)/Python/syno.install: $(OUT_DIR)/Markdown/syno.install $(OUT_DIR)/Cheetah/syno.install $(OUT_DIR)/pyOpenSSL/syno.install $(OUT_DIR)/Python/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@) distclean
	cd $(dir $@) && \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	./configure --host=$(TARGET) --target=$(TARGET) \
			--build=i686-pc-linux \
			--prefix=$(INSTALL_PREFIX) \
			--with-cxx-main=$(TARGET)-g++ \
			CFLAGS="-DPATH_MAX=4096 -mfloat-abi=soft $(CFLAGS)" LDFLAGS="$(LDFLAGS)" CPPFLAGS="$(CPPFLAGS)"
	make -C $(dir $@) HOSTPYTHON=./hostpython HOSTPGEN=./Parser/hostpgen \
			BLDSHARED="$(TARGET)-gcc -shared" CROSS_COMPILE=$(TARGET)- \
			CROSS_COMPILE_TARGET=yes
	make -C $(dir $@) DESTDIR=$(ROOT) INSTALL_PREFIX=$(ROOT) install HOSTPYTHON=./hostpython \
			HOSTPGEN=./Parser/hostpgen BLDSHARED="$(TARGET)-gcc -shared" \
			CROSS_COMPILE=$(TARGET)- CROSS_COMPILE_TARGET=yes
	touch $@

$(OUT_DIR)/bzip2/syno.install: $(OUT_DIR)/bzip2/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@) libbz2.a bzip2 bzip2recover CC="$(TARGET)-gcc" AR="$(TARGET)-ar" RANLIB="$(TARGET)-ranlib" LDFLAGS="$(LDFLAGS)"
	make -C $(dir $@) install PREFIX="$(TEMPROOT)"
	touch $@

$(OUT_DIR)/sysvinit/syno.install: $(OUT_DIR)/sysvinit/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@) SBIN="killall5" CC="$(TARGET)-gcc" LDFLAGS="$(LDFLAGS)" CFLAGS="$(CFLAGS)" CPPFLAGS="$(CPPFLAGS)"
	mkdir -p $(ROOT)/bin/
	cp $(dir $@)src/killall5 $(ROOT)/bin/
	touch $@

$(OUT_DIR)/tcl/syno.install: $(OUT_DIR)/tcl/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)unix
	make -C $(dir $@)unix DESTDIR=$(TEMPROOT) INSTALL_PREFIX=$(TEMPROOT) install
	touch $@

$(OUT_DIR)/coreutils/syno.install: $(OUT_DIR)/coreutils/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)lib
	make -C $(dir $@)src
	mkdir -p $(ROOT)/bin/
	cp $(dir $@)src/nice $(ROOT)/bin/
	touch $@

$(OUT_DIR)/util-linux-ng/syno.install: $(OUT_DIR)/util-linux-ng/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@)schedutils ionice
	mkdir -p $(ROOT)/bin/
	cp $(dir $@)schedutils/ionice $(ROOT)/bin/
	touch $@

$(OUT_DIR)/psmisc/syno.install: $(OUT_DIR)/psmisc/syno.config
	@echo $@ ----\> $^
	make -C $(dir $@) ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
	make -C $(dir $@) DESTDIR=$(ROOT) INSTALL_PREFIX=$(ROOT) install
	touch $@

$(OUT_DIR)/Markdown/syno.install: $(OUT_DIR)/Python/syno.config $(OUT_DIR)/Markdown/syno.config
	@echo $@ ----\> $^
	cd $(OUT_DIR)/Markdown/ && \
	../Python/hostpython setup.py install --prefix $(ROOT)
	touch $@

$(OUT_DIR)/Cheetah/syno.install: $(OUT_DIR)/Markdown/syno.install $(OUT_DIR)/Cheetah/syno.config
	@echo $@ ----\> $^
	cd $(OUT_DIR)/Cheetah/ && \
	../Python/hostpython setup.py install --prefix $(ROOT)
	touch $@

$(OUT_DIR)/pyOpenSSL/syno.install: $(OUT_DIR)/Python/syno.config $(OUT_DIR)/pyOpenSSL/syno.config
	@echo $@ ----\> $^
	cd $(OUT_DIR)/pyOpenSSL/ && \
	LDFLAGS="$(LDFLAGS)" \
	../Python/hostpython setup.py install --prefix $(ROOT)
	touch $@


###################
# Packaging rules #
###################
#
SPK_NAME=$(INSTALL_PKG)
SPK_VERSION=$(shell echo $(notdir $(wildcard ext/*/$(INSTALL_PKG)*)) | sed -r -e 's/^(\w*(-linux)?(-ng)?)(-autoconf)?-?([0-9][0-9.a-zRC]+)(-stable|-gpl|-src)?\.(tgz|tar\.gz|tar\.bz2)$$/\5/g')
SPK_ARCH="$(ARCH)"

spk:
	@echo -n "Making spk $(SPK_NAME) version $(SPK_VERSION) for arch $(SPK_ARCH)..."
	@rm -rf $(OUT_DIR)/spk
	@INSTALL_PREFIX=$(INSTALL_PREFIX) SPK_NAME=$(SPK_NAME) SPK_VERSION=$(SPK_VERSION) SPK_ARCH=$(SPK_ARCH) \
	./src/buildspk.sh
	@echo " Done"
