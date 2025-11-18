SHELL := /bin/bash

.PHONY: build test lint validate ci clean

build:
	swift build -c debug

release:
	swift build -c release

test:
	swift test --package-path Packages/UMAFCore

lint:
	./scripts/swiftlint.sh

validate:
	npm run validate:envelopes

ci: build test lint validate

clean:
	rm -rf .build
