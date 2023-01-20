.ONESHELL:
.SHELL = bash
.SHELLFLAGS = -euc

.PHONY: default
default: sourcepkg

include ../versions.mk

_PKG_DIR := build
BUILD_DIR := $(_PKG_DIR)/libstrangle_$(VERSION)

export EMAIL := akdor1154@noreply.users.github.com

./$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/libstrangle: ./$(BUILD_DIR)
	(
		cd ../libstrangle
		git archive \
			--format=tar \
			--prefix libstrangle/ \
			HEAD \
	) |	(
		cd $(BUILD_DIR)
		rm -rf libstrangle
		tar -xv
		touch libstrangle
	)


_DEB_DIR := deb

DEB_DIR := $(BUILD_DIR)/$(_DEB_DIR)

DEBIAN_FILES := $(shell find ../debian/ -print)

$(BUILD_DIR)/debian: $(DEBIAN_FILES) | ./$(BUILD_DIR)
	cp --archive ../debian ./$(BUILD_DIR)/.
	(
		cd ./$(BUILD_DIR)
		dch -v$(VERSION) "automated release"
	)


.PHONY: sourcepkg
sourcepkg: | $(_PKG_DIR)/libstrangle_$(VERSION).dsc
$(_PKG_DIR)/libstrangle_$(VERSION).dsc: $(BUILD_DIR)/libstrangle ./$(BUILD_DIR)/debian
	(
		cd ./$(BUILD_DIR)
		rm -f *.dsc *.tar.xz
		dpkg-source --build .
	)



.PHONY: clean
clean:
	rm -r $(_PKG_DIR)
