PWD := ${dir $(abspath $(lastword $(MAKEFILE_LIST)))}
SRCROOT = $(abspath $(PWD)/../..)
OBJROOT = $(SRCROOT)/obj/i386/cdboot
SYMROOT = $(SRCROOT)/sym/i386
DSTROOT = $(SRCROOT)/dst/i386
DOCROOT = $(SRCROOT)/doc
IMGROOT = $(SRCROOT)/sym/cache
IMGSKELROOT = $(SRCROOT)/imgskel
CDBOOT = ${IMGROOT}/usr/standalone/i386/cdboot

DIR = cdboot
include ${SRCROOT}/Make.rules

INSTALLDIR = $(DSTROOT)/usr/standalone/i386
DIRS_NEEDED = $(SYMROOT)

all embedtheme optionrom: $(DIRS_NEEDED) $(SYMROOT)/cdboot

$(SYMROOT)/cdboot:
	@echo "	[NASM] cdboot.s"	
	@$(NASM) cdboot.s -o $(SYMROOT)/cdboot.new
	@dd if=$(SYMROOT)/boot of=$(SYMROOT)/cdboot.new conv=sync bs=2k seek=1 &> /dev/null

	@# Update cdboot with boot file size info
	@ls -l $(SYMROOT)/boot  | cut -d' ' -f 5	\
		| perl -ane "print pack('V',@F[0]);" \
		| dd of=$(SYMROOT)/cdboot.new bs=1 count=4 seek=2044 conv=notrunc &> /dev/null
	@mv $(SYMROOT)/cdboot.new $(SYMROOT)/cdboot

clean-local:
	@if [ -f "$(SYMROOT)/cdboot" ];then echo "	[RM] $(SYMROOT)/cdboot"; fi
	@rm -f $(SYMROOT)/cdboot
