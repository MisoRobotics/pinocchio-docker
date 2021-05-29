MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.SUFFIXES:

CONTAINER ?= sim_breakout
TAG ?= gcr.io/software-builds/sim_breakout-docker:latest

# Set the workspace that gets mounted when running the container.
# For example,
#   WORKSPACE=/home/me/workspace make run
WORKSPACE = $(HOME)/sim_breakout/workspace

this_dir := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: all build run client kill logs check-workspace-dir

all: build

# build: Dockerfile
# 	docker build -t $(TAG) $(this_dir) --ssh default=$(SSH_AUTH_SOCK)

build: Dockerfile
	DOCKER_BUILDKIT=1 docker build \
	--ssh=default \
	--network=host \
	--progress=plain \
	--tag=$(TAG) \
	--add-host=miso-apt:10.0.0.2 .

run: check-workspace-dir
	xhost +local:$(CONTAINER)
	@docker run --rm -it \
	--privileged \
	--user=$(shell id -u):$(shell id -g) \
	--name=$(CONTAINER) \
	--network=host \
	-e DISPLAY=$(DISPLAY) \
	-e HOST_WORKSPACE=$(WORKSPACE) \
	-e QT_X11_NO_MITSHM=1 \
	-e ROS_WS_PATH=$(WORKSPACE) \
	-e MISO_CONFIG_PATH=$(WORKSPACE)/src/config-management-manual-edits \
	-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
	-v $(HOME)/.Xauthority:/root/.Xauthority:ro \
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
