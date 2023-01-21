#include versions.mk

default: 02-binary

# build a source package from this repo
.PHONY: 01-source
01-source:
	$(MAKE) -C debian/01-source

# build a binary package from the source package above
.PHONY: 02-binary
02-binary: 01-source
	$(MAKE) -C debian/02-binary

# build a binary package directly from this repo
.PHONY: 02-binary-direct
02-binary-direct:
	dpkg-buildpackage -rfakeroot --build=binary

clean:
	$(MAKE) -C debian/01-source clean
	$(MAKE) -C debian/02-binary clean

.PHONY: compute-deps
compute-deps:
	# this outputs computed dependencies, which you can MANUALLY update+commit into
	# debian/control.
	dpkg-shlibdeps ./$${PACKAGE_NAME:?}/opt/gamescope/bin/gamescope.real \
		-O \
		-l./$${PACKAGE_NAME:?}/opt/gamescope/lib/x86_64-linux-gnu \
		-xlibwayland-server0 \
		-xlibdrm2