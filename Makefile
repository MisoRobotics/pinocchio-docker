MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.SUFFIXES:

CONTAINER ?= pinocchio
TAG ?= gcr.io/software-builds/pinocchio-docker:latest

# Set the workspace that gets mounted when running the container.
# For example,
#   WORKSPACE=/home/me/workspace make run
WORKSPACE ?= $(shell pwd)

this_dir := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: all build run client kill logs check-workspace-dir

all: build

build: Dockerfile
	docker build -t $(TAG) $(this_dir)

run: check-workspace-dir
	xhost +local:$(CONTAINER)
	@docker run --rm -it \
	--user=$(shell id -u):$(shell id -g) \
	--runtime=nvidia \
	--name=$(CONTAINER) \
	--network=host \
	-e DISPLAY=$(DISPLAY) \
	-e HOST_WORKSPACE=$(WORKSPACE) \
	-e NVIDIA_VISIBLE_DEVICES=all \
	-e NVIDIA_DRIVER_CAPABILITIES=all \
	-e QT_X11_NO_MITSHM=1 \
	-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
	-v $(HOME)/.Xauthority:/pinocchio/.Xauthority:ro \
	-v $(WORKSPACE):/home/pinocchio/workspace:rw \
	-v $(HOME)/.gitconfig:/home/pinocchio/.host.gitconfig:ro \
	-v $(HOME)/.gitmessage:/home/pinocchio/.gitmessage:ro \
	-v $(HOME)/.gnupg:/home/pinocchio/.gnpug:rw \
	--device=/dev/dri \
	$(TAG) \
	bash

kill:
	docker kill $(CONTAINER)

logs:
	docker logs $(CONTAINER)

check-workspace-dir:
	test -d $(WORKSPACE)
