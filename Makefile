.DEFAULT_GOAL := help

SHELL := bash

# BASE_DIR := $(shell cd "`dirname "$0"`" >/dev/null 2>&1 && pwd)
SHINC := ./bin/shinc

##@ Build

.PHONY: clean
clean: check-build ## Clean up
	@$(SHINC) clean

.PHONY: check-build
check-build: ## Check build binaries
	@if [[ ! -f "$(SHINC)" ]]; then argc build; fi

.PHONY: build
build: ## Compile and build binaries
	@argc build

##@ Test

.PHONY: test
test: ## Test binaries
	@$(SHINC) test

##@ Distribute

.PHONY: dist
dist: ## Distribute binaries
	@$(SHINC) dist

.PHONY: all
all: build test dist ## Build, test and distribute

##@ General

.PHONY: help
help: ## Display help messages
	@./.make/help "$(MAKEFILE_LIST)"
