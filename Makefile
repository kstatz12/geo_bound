SHELL := /bin/bash
MIX   ?= mix
ELIXIR_ENV ?= test

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR := $(ROOT_DIR)/scripts
DATA_DIR := $(ROOT_DIR)/data

DOCKER_IMAGE := geonames-processor

.PHONY: help deps compile clean test test-all fmt fmt-check credo dialyzer cover \
        docker-build docker-run docker docker-clean ci

help:
	@echo "Targets:"
	@echo "  deps            Fetch deps"
	@echo "  compile         Compile umbrella"
	@echo "  test            Run tests"
	@echo "  docker-build    Build GeoNames Docker image"
	@echo "  docker-run      Run GeoNames Docker container"
	@echo "  docker          Build + run GeoNames container"
	@echo "  ci              CI pipeline"

deps:
	$(MIX) deps.get

compile:
	$(MIX) compile

clean:
	$(MIX) clean
	@rm -rf _build deps .elixir_ls

test:
	MIX_ENV=test $(MIX) test

test-all:
	MIX_ENV=test $(MIX) compile --warnings-as-errors
	MIX_ENV=test $(MIX) test

fmt:
	$(MIX) format

fmt-check:
	$(MIX) format --check-formatted

credo:
	$(MIX) credo --strict

dialyzer:
	MIX_ENV=dev $(MIX) dialyzer

cover:
	MIX_ENV=test $(MIX) coveralls.html

# --------------------------------------------------
# Docker (scripts/ directory)
# --------------------------------------------------

docker-build:
	cd $(SCRIPTS_DIR) && \
	docker build -t $(DOCKER_IMAGE) .

docker-run:
	docker run --rm \
		-v "$(DATA_DIR):/data" \
		$(DOCKER_IMAGE)

docker: docker-build docker-run

docker-clean:
	docker rmi $(DOCKER_IMAGE) || true

ci: deps fmt-check compile test credo docker-build
