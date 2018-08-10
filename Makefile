INTEGRATION  := $(shell basename $(shell pwd))
BINARY_NAME   = nr-$(INTEGRATION)
GO_PKGS      := $(shell go list ./src/... | grep -v "/vendor/")
GO_FILES     := $(shell find src -type f -name "*.go")
GOTOOLS       = github.com/kardianos/govendor \
		gopkg.in/alecthomas/gometalinter.v2 \
		github.com/axw/gocov/gocov \
		github.com/AlekSi/gocov-xml \
		go.datanerd.us/p/ohai/papers-go/... \

all: build

build: clean validate test-nocov compile

clean:
	@echo "=== $(INTEGRATION) === [ clean ]: Removing binaries and coverage file..."
	@rm -rfv bin coverage.xml

tools:
	@echo "=== $(INTEGRATION) === [ tools ]: Installing tools required by the project..."
	@go get $(GOTOOLS)
	@gometalinter.v2 --install

tools-update:
	@echo "=== $(INTEGRATION) === [ tools-update ]: Updating tools required by the project..."
	@go get -u $(GOTOOLS)
	@gometalinter.v2 --install

deps: tools
	@echo "=== $(INTEGRATION) === [ deps ]: Installing package dependencies required by the project..."
	@govendor sync

validate: lint license-check
validate-all: lint-all license-check

lint: deps
	@echo "=== $(INTEGRATION) === [ validate ]: Validating source code running gometalinter..."
	@gometalinter.v2 --config=.gometalinter.json ./src/...

lint-all: deps
	@echo "=== $(INTEGRATION) === [ validate ]: Validating source code running gometalinter..."
	@gometalinter.v2 --config=.gometalinter.json --enable=interfacer --enable=gosimple ./src/...

license-check:
	@echo "=== $(INTEGRATION) === [ validate ]: Validating licenses of package dependencies required by the project..."
	@papers-go validate -c ../../.papers_config.yml

compile: deps
	@echo "=== $(INTEGRATION) === [ compile ]: Building $(BINARY_NAME)..."
	@go build -o bin/$(BINARY_NAME) ./src

compile-dev: deps
	@echo "=== $(INTEGRATION) === [ compile-dev ]: Building $(BINARY_NAME) for development environment..."
	@GOOS=linux GOARCH=amd64 go build -o bin/$(BINARY_NAME) ./src

deploy-dev: compile-dev
	@echo "=== $(INTEGRATION) === [ deploy-dev ]: Deploying dev container image containing $(BINARY_NAME) in Kubernetes..."
	@skaffold run

test: deps
	@echo "=== $(INTEGRATION) === [ test ]: Running unit tests with coverage (gocov)..."
	@gocov test $(GO_PKGS) | gocov-xml > coverage.xml

test-nocov: deps
	@echo "=== $(INTEGRATION) === [ test ]: Running unit tests..."
	@go test ./src/...

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

.PHONY: all build clean tools tools-update deps validate compile test
