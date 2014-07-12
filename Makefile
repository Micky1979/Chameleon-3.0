#	Makefile for kernel booter
SRCROOT = $(CURDIR)
OBJROOT = $(SRCROOT)/obj
SYMROOT = $(SRCROOT)/sym
DSTROOT = $(SRCROOT)/dst
DOCROOT = $(SRCROOT)/doc
IMGSKELROOT = $(SRCROOT)/imgskel
CDBOOT = ${IMGROOT}/usr/standalone/i386/cdboot
PKG_BUILD_DIR = $(SYMROOT)/package

MAKEOPTS=SYMROOT=${SYMROOT}/i386

include Make.rules


THEME = default

VERSION = `cat ${SRCROOT}/version`
REVISION = `cat ${SRCROOT}/revision`
PRODUCT = Chameleon-$(VERSION)-r$(REVISION)
CDLABEL = ${PRODUCT}
ISOIMAGE = ${SYMROOT}/${CDLABEL}.iso
DISTFILE = ${SYMROOT}/${PRODUCT}

IMGROOT = $(SRCROOT)/sym/${PRODUCT}
DISTROOT= ${DSTROOT}


EXCLUDE = --exclude=.svn --exclude=.DS_Store --exclude=sym --exclude=obj \
		--exclude=package --exclude=archive --exclude=User_Guide_src --exclude=*.sh

#RC_CFLAGS = i386
ARCHLESS_RC_CFLAGS=`echo $(RC_CFLAGS) | sed 's/-arch [a-z0-9]*//g'`

GENERIC_SUBDIRS =
SUBDIRS = $(GENERIC_SUBDIRS) i386
DIST_SUBDIRS = $(SUBDIRS)

$(SRCROOT)/revision:
	@svnversion -n | tr -d [:alpha:] > $(SRCROOT)/revision

#
# Currently builds for i386
#
config rebuild_config:
	@make -C $(SRCROOT)/i386/config $@

all: $(SYMROOT) $(OBJROOT) $(CONFIG_HEADERS) $(HEADER_VERSION) $(SRCROOT)/revision
	@$(MAKE) all-recursive

dst: dist
dist image: all
	@# To force the read of auto.conf (generated by 'all' target)
	@make $@-local

dist-local image-local:
	@echo "================= Distrib ================="
	@echo "	[RM] ${IMGROOT}/Extra"
	@rm -rf ${IMGROOT}/Extra 	
	@echo "	[RM] ${IMGROOT}/usr/standalone/i386"
	@rm -rf ${IMGROOT}/usr/standalone/i386	
	@echo "	[MKDIR] ${IMGROOT}/usr/standalone/i386"			  	  
	@mkdir -p ${IMGROOT}/usr/standalone/i386
	@echo "	[MKDIR] ${IMGROOT}/Extra/Themes/Default"
	@mkdir -p ${IMGROOT}/Extra/Themes/Default				
	@echo "	[MKDIR] ${IMGROOT}/usr/bin"
	@mkdir -p ${IMGROOT}/usr/bin
	@if [ -e "$(IMGSKELROOT)" ]; then				\
		@echo "	[CP] ${IMGROOTSKEL} ${IMGROOT}"		\
		@cp -R -f "${IMGSKELROOT}"/* "${IMGROOT}";		\
	fi;								  
	@cp -f ${SYMROOT}/i386/cdboot ${CDBOOT}
	@cp -rf ${SYMROOT}/i386/modules ${IMGROOT}/Extra/
	@cp -f ${SRCROOT}/artwork/themes/default/* ${IMGROOT}/Extra/Themes/Default
	@cp -f ${SYMROOT}/i386/boot ${IMGROOT}/usr/standalone/i386
	@cp -f ${SYMROOT}/i386/boot0 ${IMGROOT}/usr/standalone/i386
	@cp -f ${SYMROOT}/i386/boot0hfs ${IMGROOT}/usr/standalone/i386
	@cp -f ${SYMROOT}/i386/boot0md ${IMGROOT}/usr/standalone/i386
	@cp -f ${SYMROOT}/i386/boot1h ${IMGROOT}/usr/standalone/i386
	@cp -f ${SYMROOT}/i386/boot1f32 ${IMGROOT}/usr/standalone/i386
#ifdef CONFIG_FDISK440
#	@cp -f ${SYMROOT}/i386/fdisk440 ${IMGROOT}/usr/bin
#endif
#ifdef CONFIG_BDMESG
#	@cp -f ${SYMROOT}/i386/bdmesg ${IMGROOT}/usr/bin    
#endif
ifdef CONFIG_KEYLAYOUT_MODULE
#	@cp -f ${SYMROOT}/i386/cham-mklayout ${IMGROOT}/usr/bin
	@echo "	[MKDIR] ${IMGROOT}/Extra/Keymaps"
	@mkdir -p ${IMGROOT}/Extra/Keymaps
	@echo "	[CP] Keymaps ${IMGROOT}/Extra/Keymaps"
	@cp -R -f "Keymaps"/* "${IMGROOT}/Extra/Keymaps/"
endif

ifdef CONFIG_ISO_ENABLE
	@echo "	[HDIUTIL] ${ISOIMAGE}"
	@hdiutil makehybrid -iso -joliet -hfs -hfs-volume-name \
		${CDLABEL} -eltorito-boot ${CDBOOT} -no-emul-boot -ov -o   \
		"${ISOIMAGE}" ${IMGROOT} -quiet 		  	  
endif
	@echo "	[GZ] ${DISTFILE}.tgz"
	@rm -f ${DISTFILE}.tar.gz
	@cd ${SYMROOT} && tar -cf ${DISTFILE}.tar ${DISTROOT}
	@cd ${SYMROOT} && gzip --best ${DISTFILE}.tar
	@mv ${DISTFILE}.tar.gz ${DISTFILE}.tgz

clean-local:
	@if [ -d "$(PKG_BUILD_DIR)" ];then echo "	[RMDIR] $(PKG_BUILD_DIR)"; fi
	@if [ -f "$(HEADER_VERSION)" ];then echo "	[RM] $(HEADER_VERSION)"; fi
	@if [ -f "$(SRCROOT)/revision" ];then echo "	[RM] $(SRCROOT)/revision"; fi
	@rm -rf "$(PKG_BUILD_DIR)" $(HEADER_VERSION) $(SRCROOT)/revision

AUTOCONF_FILES = $(SRCROOT)/auto.conf    $(SRCROOT)/autoconf.h \
				 $(SRCROOT)/autoconf.inc $(SRCROOT)/.config $(SRCROOT)/.config.old

distclean-local:
	@if [ -d "$(OBJROOT)" ];then echo "	[RMDIR] $(OBJROOT)"; fi
	@if [ -d "$(SYMROOT)" ];then echo "	[RMDIR] $(SYMROOT)"; fi
	@if [ -d "$(DSTROOT)" ];then echo "	[RMDIR] $(DSTROOT)"; fi
	@if [ -d "$(SRCROOT)/i386/modules/module_includes" ];then \
		echo "	[RMDIR] $(SRCROOT)/i386/modules/module_includes"; \
	 fi
	@for cfg in $(AUTOCONF_FILES); do if [ -f "$${cfg}" ];then echo "	[RM] $${cfg}"; fi; done
	@rm -rf $(OBJROOT) $(SYMROOT) $(DSTROOT)        \
            $(SRCROOT)/i386/modules/module_includes \
            $(AUTOCONF_FILES)

pkg installer: all
	@echo "================= Building Package ================="
	@${SRCROOT}/package/buildpkg.sh "$(SRCROOT)" "$(SYMROOT)" "$(PKG_BUILD_DIR)"

help:
	@echo   'Configuration target:'
	@echo   '  config    - Show configuration menu'
	@echo
	@echo   'Build targets:'
	@echo   '  all       - Build all targets [DEFAULT]'
	@echo   '  dist      - Build distribution tarball'
	@echo   '  pkg       - Build installer package'
	@echo
	@echo   'Cleaning targets:'
	@echo   '  clean     - Remove most generated files'
	@echo   '  distclean - Remove all generated files + config'
#@echo
# @echo   'Build options:'
# @echo   'make V=0|1 [targets] 0 => quiet build (default), 1 => verbose build'

.PHONY: config
.PHONY: clean
.PHONY: image
.PHONY: pkg
.PHONY: installer
.PHONY: help
