DOCKER = docker
IMAGE = irave/rom

rom: Dockerfile utils/docker_entrypoint.sh
	$(DOCKER) build -t $(IMAGE) .

all: rom

.PHONY: all
