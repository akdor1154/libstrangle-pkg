.ONESHELL:
SHELL = bash
.SHELLFLAGS = -euc

.PHONY: default
default: sourcepkg

include ../versions.mk

export EMAIL := akdor1154@noreply.users.github.com

./build:
	mkdir -p build
	mkdir -p build/pkg

.PHONY: orig.tar.xz
orig.tar.xz: build/libstrangle_$(UPSTREAM_VERSION).orig.tar.xz
build/libstrangle_$(UPSTREAM_VERSION).orig.tar.xz: ./build
	(
		cd ../../libstrangle
		git archive \
			--format=tar \
			--prefix pkg/libstrangle/ \
			HEAD \
	) \
	| xz -z -6 \
	> ./build/libstrangle_$(UPSTREAM_VERSION).orig.tar.xz



DEBIAN_FILES := $(shell find ../../debian/ -print)

export ALLOW_DIRTY := ""

.PHONY: debian
debian: ./build/pkg/debian
./build/pkg/debian: $(DEBIAN_FILES) ./build
	set -o pipefail
	(
		cd ../..
		if [[ -z "$${ALLOW_DIRTY}" ]]; then
			git diff --exit-code 1>&2 || exit 1
			git archive \
				--format=tar \
				HEAD \
				debian
		else
			git ls-files debian \
			| xargs tar -c 
		fi
	) | \
	(
		cd ./build/pkg
		tar -xv --preserve-permissions --exclude libstrangle
		dch --newversion $(VERSION) ""
	)


.PHONY: sourcepkg
sourcepkg: | ./build/libstrangle_$(VERSION).dsc
./build/libstrangle_$(VERSION).dsc: orig.tar.xz debian
	(
		cd ./build
		tar -xf ./libstrangle_$(UPSTREAM_VERSION).orig.tar.xz
		(
			cd ./pkg
			dpkg-source --build .
		)
	)



.PHONY: clean
clean:
	rm -rf ./build
