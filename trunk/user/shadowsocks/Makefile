THISDIR = $(shell pwd)

SRC_SS_NAME=shadowsocks-libev-3.3.5
#https://github.com/shadowsocks/shadowsocks-libev.git

SRC_SSR_NAME=shadowsocksr-libev-master
ARCHIVE_SSR_NAME=shadowsocksr-libev-master-e2373d7
#https://github.com/shadowsocksr-backup/shadowsocksr-libev.git

SRC_IPT_NAME=ipt2socks-1.1.3
SRC_SDNS_NAME=smartdns-Release46.1

MIERU_VER=3.20.0
MIERU_SRC=mieru-$(MIERU_VER)
MIERU_DIR=./cmd/mieru/
MIERU_BIN=$(THISDIR)/mieru
MIERU_TAR=$(MIERU_SRC).tar.gz
MIERU_URL=https://codeload.github.com/enfein/mieru/tar.gz/refs/tags/v$(MIERU_VER)

XRAY_VER=25.9.11
XRAY_SRC=Xray-core-$(XRAY_VER)
XRAY_DIR=./main/
XRAY_BIN=$(THISDIR)/xray
XRAY_TAR=$(XRAY_SRC).tar.gz
XRAY_URL=https://codeload.github.com/XTLS/Xray-core/tar.gz/refs/tags/v$(XRAY_VER)

HYSTERIA2_VER=v2.6.3
HYSTERIA2_SRC=hysteria-app-$(HYSTERIA2_VER)
HYSTERIA2_DIR=./app/
HYSTERIA2_BIN=$(THISDIR)/hysteria2
HYSTERIA2_TAR=$(HYSTERIA2_SRC).tar.gz
HYSTERIA2_URL=https://codeload.github.com/apernet/hysteria/tar.gz/refs/tags/app/$(HYSTERIA2_VER)

NAIVE_VER=v140.0.7339.123-1
NAIVE_SRC=naiveproxy-$(NAIVE_VER)-openwrt-mipsel_24kc-static
NAIVE_BIN=$(THISDIR)/naive
NAIVE_TAR=$(NAIVE_SRC).tar.xz
NAIVE_URL=https://github.com/klzgrad/naiveproxy/releases/download/$(NAIVE_VER)/$(NAIVE_TAR)

V2RAY_VER=5.39.0
V2RAY_SRC=v2ray-core-$(V2RAY_VER)
V2RAY_DIR=./main/
V2RAY_BIN=$(THISDIR)/v2ray
V2RAY_TAR=$(V2RAY_SRC).tar.gz
V2RAY_URL=https://codeload.github.com/v2fly/v2ray-core/tar.gz/refs/tags/v$(V2RAY_VER)

V2RAYPLUGIN_SRC=v2ray-plugin-master
V2RAYPLUGIN_DIR=./
V2RAYPLUGIN_BIN=$(THISDIR)/ss-v2ray-plugin
V2RAYPLUGIN_ZIP=$(V2RAYPLUGIN_SRC).zip
V2RAYPLUGIN_URL=https://codeload.github.com/shadowsocks/v2ray-plugin/zip/refs/heads/master

CACERT_NAME=cacert.pem
CACERT_URL=https://curl.se/ca/$(CACERT_NAME)
CACERT_DIR=cacerts

CHNROUTE_DIR=chnroute
CHNROUTE_URL=http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest

DOMAINLIST_DIR=domain-list-community-master
DOMAINLIST_ZIP=domain-list-community-master.zip
DOMAINLIST_URL=https://codeload.github.com/v2fly/domain-list-community/zip/refs/heads/master

all: download_test extract_test config_test build_test

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS),y)
download_test: mieru_dl xray_dl hysteria2_dl naive_dl v2ray_dl v2rayplugin_dl cacert_dl chnroute_dl domainlist_dl
else
download_test:
endif

mieru_dl:
	( if [ ! -e $(MIERU_TAR) ]; then \
		wget -t8 -4 --timeout=8 -O $(MIERU_TAR) $(MIERU_URL); \
	fi )

xray_dl:
	( if [ ! -e $(XRAY_TAR) ]; then \
		wget -t8 -4 --timeout=8 -O $(XRAY_TAR) $(XRAY_URL); \
	fi )

hysteria2_dl:
	( if [ ! -e $(HYSTERIA2_TAR) ]; then \
		wget -t8 -4 --timeout=8 -O $(HYSTERIA2_TAR) $(HYSTERIA2_URL); \
	fi )

naive_dl:
	( if [ ! -e $(NAIVE_TAR) ]; then \
		wget -t8 -4 --timeout=8 -O $(NAIVE_TAR) $(NAIVE_URL); \
	fi )

v2ray_dl:
	( if [ ! -e $(V2RAY_TAR) ]; then \
		wget -t8 -4 --timeout=8 -O $(V2RAY_TAR) $(V2RAY_URL); \
	fi )

v2rayplugin_dl:
	( if [ ! -e $(V2RAYPLUGIN_ZIP) ]; then \
		wget -t8 -4 --timeout=8 -O $(V2RAYPLUGIN_ZIP) $(V2RAYPLUGIN_URL); \
	fi )

cacert_dl:
	( if [ ! -d $(CACERT_DIR) ]; then \
		mkdir -p $(CACERT_DIR) && cd $(CACERT_DIR) && \
		wget -t8 -4 --timeout=8 $(CACERT_URL) && \
		tar jcf cacerts.bz2 $(CACERT_NAME); \
	else \
		cd $(CACERT_DIR) && tar jcf cacerts.bz2 $(CACERT_NAME); \
	fi )

chnroute_dl:
	( if [ ! -d $(CHNROUTE_DIR) ]; then \
		mkdir -p $(CHNROUTE_DIR) && cd $(CHNROUTE_DIR) && \
		wget -t8 -4 --timeout=20 --no-check-certificate -U Mozilla -O route.txt.tmp '$(CHNROUTE_URL)' && sed -i '/\*/d' route.txt.tmp && \
		awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $$4, 32-log($$5)/log(2)) }' < route.txt.tmp > chnroute.txt && \
		rm -f route.txt.tmp && tar jcf chnroute.bz2 chnroute.txt ; \
	fi )

domainlist_dl:
	( if [ ! -e $(DOMAINLIST_ZIP) ]; then \
		wget -t8 -4 --timeout=8 -O $(DOMAINLIST_ZIP) $(DOMAINLIST_URL); \
	fi )

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS),y)
extract_test: extract_mieru extract_xray extract_hysteria2 extract_naive extract_v2rayplugin extract_v2ray extract_domainlist extract_sdns extract_ipt extract_ssr extract_ss
else
extract_test: extract_ss
endif

extract_mieru:
	( if [ ! -d $(MIERU_SRC) ]; then \
		tar -xf $(MIERU_TAR); \
	fi )

extract_xray:
	( if [ ! -d $(XRAY_SRC) ]; then \
		tar -xf $(XRAY_TAR); \
	fi )

extract_hysteria2:
	( if [ ! -d $(HYSTERIA2_SRC) ]; then \
		tar -xf $(HYSTERIA2_TAR); \
	fi )

extract_naive:
	( if [ ! -d $(NAIVE_SRC) ]; then \
		tar -xf $(NAIVE_TAR); \
	fi )
ifeq ($(CONFIG_FIRMWARE_INCLUDE_UPXCOMPRESS),y)
	( if [ ! -e $(NAIVE_BIN) ]; then \
		mv -f $(NAIVE_SRC)/naive $(NAIVE_BIN) && \
		chmod +x $(NAIVE_BIN) && upx-4.2.4 --best --lzma $(NAIVE_BIN); \
	fi )
else
	( if [ ! -e $(NAIVE_BIN) ]; then \
		mv -f $(NAIVE_SRC)/naive $(NAIVE_BIN); \
	fi )
endif

extract_v2ray:
	( if [ ! -d $(V2RAY_SRC) ]; then \
		tar -xf $(V2RAY_TAR); \
	fi )

extract_v2rayplugin:
	( if [ ! -d $(V2RAYPLUGIN_SRC) ]; then \
		unzip -qq $(V2RAYPLUGIN_ZIP); \
	fi )

extract_domainlist:
	( if [ ! -d $(DOMAINLIST_DIR) ]; then \
		unzip -qq $(DOMAINLIST_ZIP); \
	fi )

extract_sdns:
	( if [ ! -d $(SRC_SDNS_NAME) ]; then \
		tar -xf $(SRC_SDNS_NAME).tar.gz; \
	fi )

extract_ipt:
	( if [ ! -d $(SRC_IPT_NAME) ]; then \
		tar -xf $(SRC_IPT_NAME).tar.gz; \
	fi )

extract_ssr:
	( if [ ! -d $(SRC_SSR_NAME) ]; then \
		unzip -qq $(ARCHIVE_SSR_NAME).zip; \
	fi )

extract_ss:
	( if [ ! -d $(SRC_SS_NAME) ]; then \
		tar -xf $(SRC_SS_NAME).tar.gz; \
	fi )

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS),y)
config_test: config_ss config_ssr config_ipt config_sdns
else
config_test: config_ss
endif

config_ss:
	( if [ -f ./ss_config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure_ss && touch ss_config_done; \
	fi )

configure_ss:
	( cd $(SRC_SS_NAME) ; \
	ac_cv_prog_PCRE_CONFIG="$(STAGEDIR)/bin/pcre-config" \
	./configure \
		--prefix=/usr \
		--disable-documentation \
		--disable-ssp \
		--disable-assert \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

config_ssr:
	( if [ -f ./ssr_config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure_ssr && touch ssr_config_done; \
	fi )

configure_ssr:
	( cd $(SRC_SSR_NAME) ; \
	ac_cv_prog_PCRE_CONFIG="$(STAGEDIR)/bin/pcre-config" \
	./configure \
		--prefix=/usr \
		--disable-documentation \
		--disable-ssp \
		--disable-assert \
		--enable-system-shared-lib \
		--with-crypto-library=mbedtls \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

config_ipt:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure_ipt && touch ipt_config_done; \
	fi )

configure_ipt:

config_sdns:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure_sdns && touch sdns_config_done; \
	fi )

configure_sdns:

build_test: build_domainlist build_go
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS),y)
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_SSR_NAME)
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_IPT_NAME) CC="$(CC)"
	$(MAKE) -C $(SRC_SDNS_NAME)
endif
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_SS_NAME)

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS),y)
build_domainlist: build_gfwlist build_chnlist
else
build_domainlist:
endif

build_gfwlist:
	( if [ ! -e gfwlist/gfwlist.bz2 ]; then \
		getgfw.sh && cd gfwlist && tar jcf gfwlist.bz2 gfwlist_domain.txt; \
	fi )

build_chnlist:
	( if [ ! -e chnlist/chnlist.bz2 ]; then \
		getchn.sh && cd chnlist && tar jcf chnlist.bz2 chnlist_domain.txt; \
	fi )

ifeq ($(CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS),y)
build_go: build_mieru build_xray build_hysteria2 build_v2ray build_v2rayplugin
else
build_go:
endif

build_mieru:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_UPXCOMPRESS),y)
	( if [ ! -e $(MIERU_BIN) ]; then \
		cd $(MIERU_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(MIERU_BIN) $(MIERU_DIR) && \
		chmod +x $(MIERU_BIN) && upx-4.2.4 --best --lzma $(MIERU_BIN); \
	fi )
else
	( if [ ! -e $(MIERU_BIN) ]; then \
		cd $(MIERU_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(MIERU_BIN) $(MIERU_DIR); \
	fi )
endif

build_xray:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_UPXCOMPRESS),y)
	( if [ ! -e $(XRAY_BIN) ]; then \
		cd $(XRAY_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(XRAY_BIN) $(XRAY_DIR) && \
		chmod +x $(XRAY_BIN) && upx-4.2.4 --best --lzma $(XRAY_BIN); \
	fi )
else
	( if [ ! -e $(XRAY_BIN) ]; then \
		cd $(XRAY_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(XRAY_BIN) $(XRAY_DIR); \
	fi )
endif

build_hysteria2:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_UPXCOMPRESS),y)
	( if [ ! -e $(HYSTERIA2_BIN) ]; then \
		cd $(HYSTERIA2_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(HYSTERIA2_BIN) $(HYSTERIA2_DIR) && \
		chmod +x $(HYSTERIA2_BIN) && upx-4.2.4 --best --lzma $(HYSTERIA2_BIN); \
	fi )
else
	( if [ ! -e $(HYSTERIA2_BIN) ]; then \
		cd $(HYSTERIA2_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(HYSTERIA2_BIN) $(HYSTERIA2_DIR); \
	fi )
endif

build_v2ray:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_UPXCOMPRESS),y)
	( if [ ! -e $(V2RAY_BIN) ]; then \
		cd $(V2RAY_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(V2RAY_BIN) $(V2RAY_DIR) && \
		chmod +x $(V2RAY_BIN) && upx-4.2.4 --best --lzma $(V2RAY_BIN); \
	fi )
else
	( if [ ! -e $(V2RAY_BIN) ]; then \
		cd $(V2RAY_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(V2RAY_BIN) $(V2RAY_DIR); \
	fi )
endif

build_v2rayplugin:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_UPXCOMPRESS),y)
	( if [ ! -e $(V2RAYPLUGIN_BIN) ]; then \
		cd $(V2RAYPLUGIN_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(V2RAYPLUGIN_BIN) $(V2RAYPLUGIN_DIR) && \
		chmod +x $(V2RAYPLUGIN_BIN) && upx-4.2.4 --best --lzma $(V2RAYPLUGIN_BIN); \
	fi )
else
	( if [ ! -e $(V2RAYPLUGIN_BIN) ]; then \
		cd $(V2RAYPLUGIN_SRC) && \
		env GOOS=linux GOARCH=mipsle CGO_ENABLED=0 go build -trimpath -ldflags "-w -s" -o $(V2RAYPLUGIN_BIN) $(V2RAYPLUGIN_DIR); \
	fi )
endif

clean: clean_mieru clean_xray clean_hysteria2 clean_naive clean_v2ray clean_v2rayplugin clean_sdns clean_ipt clean_ssr clean_ss
	rm -f ssr_config_done ss_config_done ipt_config_done sdns_config_done
	rm -f gfwlist/gfwlist.bz2
	rm -f chnlist/chnlist.bz2
	rm -rf $(DOMAINLIST_DIR)
	rm -rf $(CHNROUTE_DIR)
	rm -rf $(CACERT_DIR)

clean_mieru:
	( if [ -e $(MIERU_BIN) ]; then \
		rm -rf $(MIERU_BIN); \
	fi )
	( if [ -d $(MIERU_SRC) ]; then \
		rm -rf $(MIERU_SRC); \
	fi )

clean_xray:
	( if [ -e $(XRAY_BIN) ]; then \
		rm -rf $(XRAY_BIN); \
	fi )
	( if [ -d $(XRAY_SRC) ]; then \
		rm -rf $(XRAY_SRC); \
	fi )

clean_hysteria2:
	( if [ -e $(HYSTERIA2_BIN) ]; then \
		rm -rf $(HYSTERIA2_BIN); \
	fi )
	( if [ -d $(HYSTERIA2_SRC) ]; then \
		rm -rf $(HYSTERIA2_SRC); \
	fi )

clean_naive:
	( if [ -e $(NAIVE_BIN) ]; then \
		rm -rf $(NAIVE_BIN); \
	fi )
	( if [ -d $(NAIVE_SRC) ]; then \
		rm -rf $(NAIVE_SRC); \
	fi )

clean_v2ray:
	( if [ -e $(V2RAY_BIN) ]; then \
		rm -rf $(V2RAY_BIN); \
	fi )
	( if [ -d $(V2RAY_SRC) ]; then \
		rm -rf $(V2RAY_SRC); \
	fi )

clean_v2rayplugin:
	( if [ -e $(V2RAYPLUGIN_BIN) ]; then \
		rm -rf $(V2RAYPLUGIN_BIN); \
	fi )
	( if [ -d $(V2RAYPLUGIN_SRC) ]; then \
		rm -rf $(V2RAYPLUGIN_SRC); \
	fi )

clean_sdns:
	( if [ -f $(SRC_SDNS_NAME)/Makefile ]; then \
		$(MAKE) -C $(SRC_SDNS_NAME) clean; \
	fi )

clean_ipt:
	( if [ -f $(SRC_IPT_NAME)/Makefile ]; then \
		$(MAKE) -C $(SRC_IPT_NAME) clean; \
	fi )

clean_ssr:
	( if [ -f $(SRC_SSR_NAME)/Makefile ]; then \
		$(MAKE) -C $(SRC_SSR_NAME) clean; \
	fi )

clean_ss:
	( if [ -f $(SRC_SS_NAME)/Makefile ]; then \
		$(MAKE) -C $(SRC_SS_NAME) distclean; \
	fi )

romfs:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSSERVER),y)
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_SS_NAME)/src/ss-server /usr/bin/ss-server
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS),y)
	[ -d $(SSP_DIR) ] || mkdir -p $(SSP_DIR)
	chmod -R +x scripts/
	$(ROMFSINST) $(THISDIR)/scripts/shadowsocks.sh /usr/bin/shadowsocks.sh
	$(ROMFSINST) $(THISDIR)/scripts/ss-rules /usr/bin/ss-rules
	$(ROMFSINST) $(THISDIR)/scripts/ss-watchcat.sh /usr/bin/ss-watchcat.sh
	$(ROMFSINST) $(THISDIR)/scripts/update_gfwlist.sh /usr/bin/update_gfwlist.sh
	$(ROMFSINST) $(THISDIR)/scripts/update_chnlist.sh /usr/bin/update_chnlist.sh
	$(ROMFSINST) $(THISDIR)/scripts/update_chnroute.sh /usr/bin/update_chnroute.sh
	$(ROMFSINST) $(THISDIR)/gfwlist/gfwlist.bz2 /etc_ro/gfwlist.bz2
	$(ROMFSINST) $(THISDIR)/chnlist/chnlist.bz2 /etc_ro/chnlist.bz2
	$(ROMFSINST) $(THISDIR)/chnroute/chnroute.bz2 /etc_ro/chnroute.bz2
	$(ROMFSINST) $(THISDIR)/cacerts/cacerts.bz2 /etc_ro/cacerts.bz2
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_IPT_NAME)/ipt2socks /usr/bin/ipt2socks
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_SDNS_NAME)/src/smartdns /usr/bin/smartdns
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_SSR_NAME)/src/ss-local /usr/bin/ssr-local
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_SS_NAME)/src/ss-local /usr/bin/ss-orig-local
	ln -sf /var/ss-local $(ROMFSDIR)/usr/bin/ss-local
	ln -sf /var/v2ray-plugin $(ROMFSDIR)/usr/bin/v2ray-plugin
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSV2RP),y)
	$(ROMFSINST) -p +x $(V2RAYPLUGIN_BIN) /usr/bin/ss-v2ray-plugin
else
	cp -fp $(V2RAYPLUGIN_BIN) $(SSP_DIR)/
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSVMESS),y)
	$(ROMFSINST) -p +x $(V2RAY_BIN) /usr/bin/v2ray
else
	cp -fp $(V2RAY_BIN) $(SSP_DIR)/
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSNAIVE),y)
	$(ROMFSINST) -p +x $(NAIVE_BIN) /usr/bin/naive
else
	cp -fp $(NAIVE_BIN) $(SSP_DIR)/
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSHYSTERIA2),y)
	$(ROMFSINST) -p +x $(HYSTERIA2_BIN) /usr/bin/hysteria2
else
	cp -fp $(HYSTERIA2_BIN) $(SSP_DIR)/
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSVLESS),y)
	$(ROMFSINST) -p +x $(XRAY_BIN) /usr/bin/xray
else
	cp -fp $(XRAY_BIN) $(SSP_DIR)/
endif
ifeq ($(CONFIG_FIRMWARE_INCLUDE_SSMIERU),y)
	$(ROMFSINST) -p +x $(MIERU_BIN) /usr/bin/mieru
else
	cp -fp $(MIERU_BIN) $(SSP_DIR)/
endif
endif

