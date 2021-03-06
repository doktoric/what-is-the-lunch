
BINARY=ch

BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
VERSION?=$(shell git describe --tags --abbrev=0)-snapshot
PKG_BASE=github.com/doktoric/what-is-the-lunch
BUILD_TIME=$(shell date +%FT%T)
LDFLAGS=-X $(PKG_BASE)/context.Version=${VERSION} -X $(PKG_BASE)/context.BuildTime=${BUILD_TIME}

GOFILES_NOVENDOR = $(shell find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./.git/*")

all: deps build

deps: deps-errcheck
	go get -u github.com/golang/dep/cmd/dep
	# go get -u golang.org/x/tools/cmd/goimports
	go get -u github.com/keyki/glu

deps-errcheck:
	go get -u github.com/kisielk/errcheck

_check: errcheck formatcheck vet

formatcheck:
	([ -z "$(shell gofmt -d $(GOFILES_NOVENDOR))" ]) || (echo "Source is unformatted"; exit 1)

format:
	gofmt -s -w $(GOFILES_NOVENDOR)

vet:
	go vet ./...

test:
	go test -timeout 30s -coverprofile coverage -race $$(go list ./... | grep -v /vendor/)

errcheck:
	errcheck -ignoretests ./...

_build: build-darwin build-linux

build: _check test _build

cleanup:
	rm -rf release && mkdir release

build-docker:
	@#USER_NS='-u $(shell id -u $(whoami)):$(shell id -g $(whoami))'
	docker run --rm ${USER_NS} -v "${PWD}":/go/src/$(PKG_BASE) -w /go/src/$(PKG_BASE) golang:1.9 make deps-errcheck build

build-darwin:
	GOOS=darwin CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)" -o build/Darwin/${BINARY} main.go

build-linux:
	GOOS=linux CGO_ENABLED=0 go build -ldflags "$(LDFLAGS)" -o build/Linux/${BINARY} main.go

release: cleanup build
	glu release

download:
	curl -LOs https://github.com/doktoric/what-is-the-lunch/releases/download/v$(VERSION)/what-is-the-lunch_$(VERSION)_$(shell uname)_x86_64.tgz
	tar -xvf what-is-the-lunch_$(VERSION)_$(shell uname)_x86_64.tgz