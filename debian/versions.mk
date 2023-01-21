_debian := $(dir $(lastword $(MAKEFILE_LIST)))
UPSTREAM_VERSION := $(shell \
	cd $(_debian)/../libstrangle; \
	git describe --tags HEAD | sed s/-/~/g \
)
MY_VERSION := $(shell \
	cd $(_debian)/..; \
	LAST_TAG=$$(git rev-list --tags=upstream-\* --max-count=1); \
	git rev-list $${LAST_TAG}..HEAD --count \
)
VERSION := $(UPSTREAM_VERSION)-$(MY_VERSION)