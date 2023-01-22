.ONESHELL:
.SHELL = bash
.SHELLFLAGS = -euc

include ../versions.mk

default: package

DSC := libstrangle_$(VERSION).dsc

./src_package: $(DSC)
	rm -rf ./src_package_tmp ./src_package
	mkdir ./src_package_tmp
	(
		cd ./src_package_tmp
		dpkg-source --extract ../$(DSC)
	)
	mv -T src_package_tmp src_package


.PHONY: image
image: ./src_package
	mkdir -p ./.cache/image-apt-cache
	DEPS="$$(./02-binary/build_deps.pl './src_package/libstrangle-$(UPSTREAM_VERSION)/debian/control')"
	podman build \
		--tag libstranglebuildimg \
		--volume $$(pwd)/.cache/image-apt-cache:/var/cache/apt:U \
		--build-arg BUILD_DEPS="$${DEPS}" \
		-f 02-binary/package.Containerfile .

.PHONY: package
package: image ./src_package
	set -x

	podman create \
		--name libstranglebuild \
		--volume .:/src \
		--workdir /src/src_package/libstrangle-$(UPSTREAM_VERSION) \
		libstranglebuildimg \
		dpkg-buildpackage -rfakeroot --build=binary

	trap "podman rm libstranglebuild" EXIT

	podman start --attach libstranglebuild

clean:
	rm -rf src_package