.ONESHELL:
SHELL = bash
.SHELLFLAGS = -euc

.PHONY: default
default: sourcepkg

include ./versions.mk

libstrangle_$(UPSTREAM_VERSION).orig.tar.xz:
	(
		cd ./package/libstrangle
		git archive \
			--format=tar \
			--prefix package/libstrangle/ \
			HEAD \
	) \
	| xz -z -6 \
	> ./libstrangle_$(UPSTREAM_VERSION).orig.tar.xz


export ALLOW_DIRTY := 

.PHONY: sourcepkg
sourcepkg: | libstrangle_$(VERSION).dsc
libstrangle_$(VERSION).dsc: libstrangle_$(UPSTREAM_VERSION).orig.tar.xz
	if [[ -z "$${ALLOW_DIRTY}" ]]; then
		git diff --exit-code 1>&2 || exit 1
	fi

	cd ./package
	dpkg-source --build .


.PHONY: clean
clean:
	rm -rf ./build
