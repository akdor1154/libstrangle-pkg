.ONESHELL:
SHELL = bash
.SHELLFLAGS = -euc

default: 02-binary

include versions.mk
VERSION := $(UPSTREAM_VERSION)-$(MY_VERSION)

export ALLOW_DIRTY := 

###
### SOURCE PACKAGE
###

ORIG.tar.xz := libstrangle_$(UPSTREAM_VERSION).orig.tar.xz
DSC := libstrangle_$(VERSION).dsc

.PHONY: 01-source
01-source: | $(DSC)

.PHONY: check-version
check-version:
	CHECKED_VERSION=$$(
		cd package/libstrangle;
		git describe --tags HEAD | sed s/-/~/g
	)
	if [[ "$${CHECKED_VERSION:?}" != "$(UPSTREAM_VERSION)" ]]; then
		echo "version mismatch! submodule checkout is $${CHECKED_VERSION}, but versions.mk is $(UPSTREAM_VERSION)!" 1>&1
		exit 1
	fi
	CHANGELOG_VERSION=$$(
		dpkg-parsechangelog -l package/debian/changelog --show-field Version
	)
	if [[ "$${CHANGELOG_VERSION}" != "$(VERSION)" ]]; then
		echo "version mismatch! changelog version is $${CHANGELOG_VERSION}, but versions.mk is $(VERSION)!" 1>&2
		echo "run \`make changelog\` to fix." 1>&2
		exit 1
	fi

# build the orig.tar.xz tarball from the project's submodule directory
$(ORIG.tar.xz): check-version
	(
		cd ./package/libstrangle
		git archive \
			--format=tar \
			--prefix package/libstrangle/ \
			HEAD \
	) \
	| xz -z -6 \
	> ./$(ORIG.tar.xz)

# build the .dsc source package file
$(DSC): $(ORIG.tar.xz)
	if [[ -z "$${ALLOW_DIRTY}" ]]; then
		git diff --exit-code 1>&2 || exit 1
	fi

	cd ./package
	dpkg-source --build .

.PHONY: clean-source
clean-source:
	rm -f $(ORIG.tar.xz)
	rm -f $(DSC)
	rm -f *.debian.tar.xz

###
### BINARY PACKAGE FROM SOURCE PACKAGE
###

.PHONY: 02-binary
02-binary: | package

# extract the contents of the source package into ./src_package
./src_package: $(DSC)
	rm -rf ./src_package_tmp ./src_package
	dpkg-source --extract $(DSC) ./src_package_tmp
	mv -T src_package_tmp src_package

# set up a container with the source package's build dependencies to build it
.PHONY: image
image: ./src_package
	mkdir -p ./.cache/image-apt-cache
	DEPS="$$(./02-binary/build_deps.pl './src_package/debian/control')"
	podman build \
		--tag libstranglebuildimg \
		--volume $$(pwd)/.cache/image-apt-cache:/var/cache/apt:U \
		--build-arg BUILD_DEPS="$${DEPS}" \
		-f 02-binary/package.Containerfile .

# build the package inside the container
.PHONY: package
package: image ./src_package
	set -x

	podman create \
		--name libstranglebuild \
		--volume .:/src \
		--workdir /src/src_package/ \
		libstranglebuildimg \
		dpkg-buildpackage -rfakeroot --build=binary

	trap "podman rm libstranglebuild" EXIT

	podman start --attach libstranglebuild

.PHONY: clean-binary
clean-binary:
	rm -rf ./src_package
	rm -f *.buildinfo
	rm -f *.changes
	rm -f *.deb
	(
		cd package
		debian/rules clean
	)


###
### BINARY PACKAGE direct from the current contents of this repo
###

.PHONY: package-direct
package-direct:
	cd package
	dpkg-buildpackage -rfakeroot --build=binary

clean: clean-source clean-binary


###
### RELEASE MANAGEMENT
###

export EMAIL := akdor1154@noreply.users.github.com

.PHONY: changelog
changelog:
	cd package
	dch -v$(VERSION)

TAG_SAFE_VERSION := $(shell echo "$(VERSION)" | sed s/~/_/g )
export VERSION
export TAG_SAFE_VERSION

.PHONY: release
release: check-version
	(
		cd package
		dch --distribution stable --release
	)
	git add -p
	git commit -m "v$${VERSION:?}"
	git tag -a "v$${TAG_SAFE_VERSION:?}" -m "v$${VERSION:?}"

.PHONY: github_release
github_release:
	git name-rev --name-only --tags --refs v$${TAG_SAFE_VERSION:?} --no-undefined HEAD || exit 1
	(
		echo '```'
		dpkg-parsechangelog -l package/debian/changelog
		echo '```'
	) > gh_changelog
	gh release create "v$${VERSION:?}" \
		--title "v$${VERSION:?}" \
		--notes-file gh_changelog \
		--draft \
		libstrangle_$${VERSION:?}_amd64.deb \
		$(DSC) \
		$(ORIG.tar.xz) \
		libstrangle_$${VERSION:?}.debian.tar.xz


.PHONY: compute-deps
compute-deps:
	# this outputs computed dependencies, which you can MANUALLY update+commit into
	# debian/control.
	dpkg-shlibdeps ./$${PACKAGE_NAME:?}/opt/gamescope/bin/gamescope.real \
		-O \
		-l./$${PACKAGE_NAME:?}/opt/gamescope/lib/x86_64-linux-gnu \
		-xlibwayland-server0 \
		-xlibdrm2