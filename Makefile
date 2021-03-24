MAKEFLAGS += --warn-undefined-variables -j$(shell nproc)
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.SUFFIXES:

CONTAINER ?= pinocchio
TAG ?= gcr.io/software-builds/pinocchio-docker:latest

export COLOR ?=
export MAKESILENT ?=
export VERBOSE ?=

this_dir := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: all build run client kill logs

all: build

build: Dockerfile
	DOCKER_BUILDKIT=1 docker build \
	-t $(TAG) \
	--progress=plain \
	$(this_dir)

run:
	xhost +local:$(CONTAINER)
	docker run --rm -it \
	--runtime=nvidia \
	--name=$(CONTAINER) \
	--network=host \
	-e "DISPLAY=${DISPLAY}" \
	-e NVIDIA_VISIBLE_DEVICES=all \
	-e NVIDIA_DRIVER_CAPABILITIES=all \
	-e QT_X11_NO_MITSHM=1 \
	-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
	-v ${HOME}/.Xauthority:/root/.Xauthority:ro \
	--device=/dev/dri \
	$(TAG) \
	bash

kill:
	docker kill $(CONTAINER)

logs:
	docker logs $(CONTAINER)
