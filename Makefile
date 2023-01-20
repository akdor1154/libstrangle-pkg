include versions.mk

default: 02-binary

.PHONY: 01-source
01-source:
	$(MAKE) -C 01-source

.PHONY: 02-binary
02-binary: 01-source
	$(MAKE) -C 02-binary

clean:
	$(MAKE) -C 01-source clean
	$(MAKE) -C 02-binary clean

.PHONY: compute-deps
compute-deps:
	# this outputs computed dependencies, which you can MANUALLY update+commit into
	# debian/control.
	dpkg-shlibdeps ./$${PACKAGE_NAME:?}/opt/gamescope/bin/gamescope.real \
		-O \
		-l./$${PACKAGE_NAME:?}/opt/gamescope/lib/x86_64-linux-gnu \
		-xlibwayland-server0 \
		-xlibdrm2