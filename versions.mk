_root := $(dir $(lastword $(MAKEFILE_LIST)))
UPSTREAM_VERSION := $(shell \
	cd $(_root)/package/libstrangle; \
	git describe --tags HEAD | sed s/-/~/g \
)
MY_VERSION := 1
VERSION := $(UPSTREAM_VERSION)-$(MY_VERSION)