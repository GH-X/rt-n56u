SRC_NAME = smartdns-Release01
THISDIR = $(shell pwd)

all: extract_tar config_sdns
	$(MAKE) -C $(SRC_NAME)

extract_tar:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar zxf $(SRC_NAME).tar.gz ; \
	fi )

config_sdns:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		touch config_done; \
	fi )

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_NAME)/src/smartdns /usr/bin/smartdns
	$(ROMFSINST) -p +x $(THISDIR)/smartdns.sh /usr/bin/smartdns.sh
	$(ROMFSINST) /etc_ro/smartdns_address.conf
	$(ROMFSINST) /etc_ro/smartdns_blacklist.conf
	$(ROMFSINST) /etc_ro/smartdns_custom.conf
	$(ROMFSINST) /etc_ro/smartdns_whitelist.conf
	$(ROMFSINST) /etc_ro/ca-certificates.crt
	$(ROMFSINST) /etc_ro/GFWblack.conf
	$(ROMFSINST) /etc_ro/GFWblackip.conf
	$(ROMFSINST) /etc_ro/CHNwhiteip.conf
	