.ONESHELL:
.SHELL = bash
.SHELLFLAGS = -euc

include ../versions.mk

default: package

DSC := ../01-source/build/libstrangle_$(VERSION).dsc

./build: $(DSC)
	rm -rf ./build_tmp ./build
	mkdir ./build_tmp
	(
		cd ./build_tmp
		dpkg-source --extract ../$(DSC)
	)
	mv -T build_tmp build


.PHONY: image
image: ./build
	mkdir -p ../.cache/image-apt-cache
	DEPS="$$(./build_deps.pl './build/libstrangle-$(UPSTREAM_VERSION)/debian/control')"
	podman build \
		--tag libstranglebuildimg \
		--volume $$(pwd)/../.cache/image-apt-cache:/var/cache/apt:U \
		--build-arg BUILD_DEPS="$${DEPS}" \
		-f package.Containerfile .

.PHONY: package
package: image ./build
	set -x

	rm -rf ./package

	podman create \
		--name libstranglebuild \
		--volume .:/02-binary \
		--workdir /02-binary/build/libstrangle-$(UPSTREAM_VERSION) \
		libstranglebuildimg \
		dpkg-buildpackage -rfakeroot --build=binary

	trap "podman rm libstranglebuild" EXIT

	podman start --attach libstranglebuild

clean:
	rm -rf build