#!/usr/bin/make -ef

VERSION ?= $(shell cat mix.exs | grep version | sed -e 's/.*version: "\(.*\)",/\1/')

# Exporting the config values allows us to generate Dockerfile and github config using envsubst.
export KUBO_VERSION ?= v0.18.1
export DOCKER_USER ?= bahner
export DOCKER_IMAGE ?= $(DOCKER_USER)/kubo:$(KUBO_VERSION)

all: deps format compile test

commited: templates
	./.check.uncommited

compile:
	mix compile

deps:
	mix deps.get

services:
	docker-compose up -d

docs:
	mix docs
	xdg-open doc/index.html

cover:
	mix coveralls.html
	xdg-open cover/excoveralls.html

image: templates
	docker build -t $(DOCKER_IMAGE) --no-cache .

format:
	mix format

map:
	mix xref graph --format dot
	dot -Tpng xref_graph.dot -o xref_graph.png
	eog xref_graph.png

mix: compile
	iex -S mix

proper: distclean compile test

push: all commited test
	git pull
	git push

publish: test
	mix hex.publish

test: deps services
	mix format --check-formatted
	mix dialyzer
	mix test

distclean: clean
	rm -rf _build deps mix.lock
	git ls-files -o | xargs rm -f

clean:
	rm -f Qm*
	rm -rf cover

.PHONY: compile deps docs docker test templates cover
