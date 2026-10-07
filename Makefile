.ONESHELL:
SHELL := $(shell command -v bash)
.SHELLFLAGS := -euo pipefail -c
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
.SILENT:

VERSION ?=
export VERSION

.PHONY: all clean build

all: clean build

clean:
	rm -f "$(MAKEFILE_DIR)dist/"*
	mkdir -p "$(MAKEFILE_DIR)dist"

build:
	test -n "$(VERSION)"
	for pkg in deb rpm archlinux; do
		nfpm package \
			-f "$(MAKEFILE_DIR)nfpm.yaml" \
			-p "$$pkg" \
			-t "$(MAKEFILE_DIR)dist/"
	done

	for ext in rpm deb pkg.tar.zst; do
		cp "$(MAKEFILE_DIR)dist/"*."$$ext" "$(MAKEFILE_DIR)dist/cubex-latest.$$ext"
	done
