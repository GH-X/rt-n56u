# use host target
CC        = gcc
GCC       = gcc
CXX       = g++
AS        = as
AR        = ar
LD        = ld
NM        = nm
OBJCOPY   = objcopy
RANLIB    = ranlib
STRIP     = strip
STRIPTOOL = $(STRIP)
SSTRIP_NAME = ELFkickers-3.1

CFLAGS    = -Wall -O2
LDFLAGS   =

THISDIR = $(shell pwd)
GO_TAR  = go1.24.0.linux-amd64.tar.gz
GO_URL  = https://dl.google.com/go/$(GO_TAR)
GO_DIR  = go

-include $(LINUX_CONFIG)

all: golang upx
	make -C mkimage
	mkdir -p sstrip
	make -C $(SSTRIP_NAME)
	make -C lzma
ifeq ($(CONFIG_RT2880_ROOTFS_IN_FLASH),y)
	make -C mksquashfs_xz
endif

golang:
	( if [ ! -e $(GO_TAR) ]; then \
		wget -t8 -4 --timeout=8 $(GO_URL); \
	fi )
	( if [ ! -d $(GO_DIR) ]; then \
		mkdir -p $(GO_DIR) && \
		tar -xf $(GO_TAR) -C $(THISDIR); \
	fi )

upx:
	( if [ ! -e $(THISDIR)/upx-4.2.4-amd64_linux.tar.xz ]; then \
		wget -t8 -4 --timeout=8 https://github.com/upx/upx/releases/download/v4.2.4/upx-4.2.4-amd64_linux.tar.xz; \
	fi )
	( if [ ! -e $(THISDIR)/upx ]; then \
		tar -xf upx-4.2.4-amd64_linux.tar.xz && \
		mv -f $(THISDIR)/upx-4.2.4-amd64_linux/upx $(THISDIR)/upx && \
		ln -sf $(THISDIR)/upx $(THISDIR)/upx-4.2.4 && \
		rm -rf $(THISDIR)/upx-4.2.4-amd64_linux; \
	fi )

clean:
	if [ -f $(SSTRIP_NAME)/Makefile ] ; then \
		make -C $(SSTRIP_NAME) clean ; \
	fi ;
	rm -rf sstrip
	make -C mkimage clean
	make -C lzma clean
	make -C mksquashfs_xz clean
