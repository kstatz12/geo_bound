SHELL := /bin/bash
MIX   ?= mix
ELIXIR_ENV ?= test

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR := $(ROOT_DIR)/scripts
DATA_DIR := $(ROOT_DIR)/data

DOCKER_IMAGE := geonames-processor

# Detect container runtime (docker preferred, fallback to podman)
DOCKER := $(shell command -v docker 2>/dev/null)
PODMAN := $(shell command -v podman 2>/dev/null)

ifeq ($(DOCKER),)
  ifeq ($(PODMAN),)
    $(error Neither docker nor podman is installed)
  else
    CONTAINER_RUNTIME := podman
  endif
else
  CONTAINER_RUNTIME := docker
endif

.PHONY: help deps compile clean test test-all fmt fmt-check credo dialyzer cover \
	data-pipeline-build data-pipeline-run data-pipeline ci 

help:
	@echo "Targets:"
	@echo "  deps            Fetch deps"
	@echo "  compile         Compile umbrella"
	@echo "  test            Run tests"
	@echo "  data-pipeline   process geonames data"
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

data-pipeline-build:
	cd $(SCRIPTS_DIR) && \
	$(CONTAINER_RUNTIME) build -t $(DOCKER_IMAGE) .

data-pipeline-run:
	$(CONTAINER_RUNTIME) run --rm \
		-v "$(DATA_DIR):/data:Z" \
		$(DOCKER_IMAGE)

data-pipeline: data-pipeline-build data-pipeline-run

data-pipeline-clean:
	$(CONTAINER_RUNTIME) rmi $(DOCKER_IMAGE) || true

# --------------------------------------------------
# CI Steps
# --------------------------------------------------
ci: deps fmt-check compile test credo
