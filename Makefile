NO_COLOR = \033[0m
O1_COLOR = \033[0;01m
O2_COLOR = \033[32;01m

PREFIX = "$(O2_COLOR)==>$(O1_COLOR)"
SUFFIX = "$(NO_COLOR)"

CURRENT_DIR = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

IMAGE_REPO			= registry.fuwafuwatime.moe/concord/asterisk-cisco-usecallmanager
IMAGE_TAG 			= latest

ASTERISK_VERSION	:= 20.6.0

default: build

.PHONY: clean
clean:
	@echo -e $(PREFIX) $@ $(SUFFIX)
	cd $(CURRENT_DIR); \
		(podman rmi $(IMAGE_REPO):$(IMAGE_TAG) || true)

.PHONY: build
build: clean
	@echo -e $(PREFIX) $@ $(SUFFIX)
	cd $(CURRENT_DIR); \
		buildah build \
			--build-arg ASTERISK_VERSION=$(ASTERISK_VERSION) \
			--tag $(IMAGE_REPO):$(IMAGE_TAG) \
			Containerfile
