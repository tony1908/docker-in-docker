IMAGE ?= docker-compose-in-docker:local
DIND_CONTAINER ?= course-dind
DIND_VOLUME ?= course-dind-var-lib-docker
IMAGE_TO_COPY ?=

.PHONY: build check shell dind-start dind-copy dind-shell dind-rm

build:
	docker build -t $(IMAGE) .

check:
	docker run --rm --privileged -v "$$PWD:/workspace" $(IMAGE) \
		sh -lc 'docker version && docker compose version && cd examples/hello && docker compose up --abort-on-container-exit'

shell:
	docker run --rm -it --privileged -v "$$PWD:/workspace" $(IMAGE)

dind-start:
	DIND_IMAGE="$(IMAGE)" DIND_CONTAINER="$(DIND_CONTAINER)" DIND_VOLUME="$(DIND_VOLUME)" WORKSPACE="$$PWD" \
		./scripts/dind.sh start

dind-copy:
	DIND_IMAGE="$(IMAGE)" DIND_CONTAINER="$(DIND_CONTAINER)" DIND_VOLUME="$(DIND_VOLUME)" WORKSPACE="$$PWD" \
		./scripts/dind.sh copy-image "$(IMAGE_TO_COPY)"

dind-shell:
	DIND_IMAGE="$(IMAGE)" DIND_CONTAINER="$(DIND_CONTAINER)" DIND_VOLUME="$(DIND_VOLUME)" WORKSPACE="$$PWD" \
		./scripts/dind.sh shell

dind-rm:
	DIND_IMAGE="$(IMAGE)" DIND_CONTAINER="$(DIND_CONTAINER)" DIND_VOLUME="$(DIND_VOLUME)" WORKSPACE="$$PWD" \
		./scripts/dind.sh rm
