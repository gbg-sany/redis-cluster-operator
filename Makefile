SHELL=/bin/bash -o pipefail

PROJECT_NAME=redis-cluster-operator
REPO=ucloud/$(PROJECT_NAME)

# replace with your public registry
ALTREPO=$(DOCKER_REGISTRY)/$(PROJECT_NAME)
E2EALTREPO=$(DOCKER_REGISTRY)/$(PROJECT_NAME)-e2e

VERSION=$(shell git describe --always --tags --dirty | sed "s/\(.*\)-g`git rev-parse --short HEAD`/\1/")
GIT_SHA=$(shell git rev-parse --short HEAD)
BIN_DIR=build/bin
.PHONY: all build check clean test login build-e2e push push-e2e build-tools

LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

CONTROLLER_GEN ?= $(LOCALBIN)/controller-gen
CONTROLLER_TOOLS_VERSION ?= v0.9.2

all: check build

build: test build-go build-image

build_go_amd64: ARCH=amd64
build_go_arm64: ARCH=arm64
build_go build_go_amd64 build_go_arm64:
	GO111MODULE=on CGO_ENABLED=0 GOOS=linux GOARCH=$(ARCH) go build \
	-ldflags "-X github.com/$(REPO)/version.Version=$(VERSION) -X github.com/$(REPO)/version.GitSHA=$(GIT_SHA)" \
	-o $(BIN_DIR)/$(PROJECT_NAME)-linux-$(ARCH) cmd/manager/main.go

build-go: build_go_amd64 build_go_arm64

build-image: ARCH=amd64
build-arm64-image: ARCH=arm64
build-image build-arm64-image:
	docker build --platform=linux/$(ARCH) --build-arg VERSION=$(VERSION) --build-arg GIT_SHA=$(GIT_SHA) --build-arg ARCH=$(ARCH) -t $(ALTREPO):$(VERSION) .
	docker tag $(ALTREPO):$(VERSION) $(ALTREPO):latest

build-e2e:
	docker build -t $(E2EALTREPO):$(VERSION)  -f test/e2e/Dockerfile .

build-tools:
	bash hack/docker/redis-tools/make.sh build

test:
	GO111MODULE=on go test $$(go list ./... | grep -v /vendor/) -race -coverprofile=coverage.txt -covermode=atomic

login:
	@docker login -u "$(DOCKER_USER)" -p "$(DOCKER_PASS)"

push: build-image
	docker push $(ALTREPO):$(VERSION)
	docker push $(ALTREPO):latest

push-e2e: build-e2e
	docker push $(E2EALTREPO):$(VERSION)

clean:
	rm -f $(BIN_DIR)/$(PROJECT_NAME)*

check: check-format

check-format:
	@test -z "$$(gofmt -s -l . 2>&1 | grep -v -e vendor/ | tee /dev/stderr)"


.PHONY: controller-gen
controller-gen: $(CONTROLLER_GEN) ## Download controller-gen locally if necessary.
$(CONTROLLER_GEN): $(LOCALBIN)
	test -s $(LOCALBIN)/controller-gen || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

.PHONY: generate
generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(CONTROLLER_GEN) object paths="./..."

# Generate manifests for CRDs
manifests: controller-gen
	$(CONTROLLER_GEN) crd paths="./pkg/apis/..." crd:generateEmbeddedObjectMeta=true output:crd:artifacts:config=deploy/crds,config=charts/$(PROJECT_NAME)/crds

compile-build-img: ARCH=amd64
compile-build-arm64-img: ARCH=arm64
compile-build-img compile-build-arm64-img: build_go
	docker build --platform=linux/$(ARCH) --build-arg ARCH=$(ARCH) build -t $(ALTREPO):latest