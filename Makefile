IMAGE ?= docker-compose-in-docker:local

.PHONY: build check shell

build:
	docker build -t $(IMAGE) .

check:
	docker run --rm --privileged -v "$$PWD:/workspace" $(IMAGE) \
		sh -lc 'docker version && docker compose version && cd examples/hello && docker compose up --abort-on-container-exit'

shell:
	docker run --rm -it --privileged -v "$$PWD:/workspace" $(IMAGE)
