DOCKER   := docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR)
COMPOSE  := $(DOCKER) -v /var/run/docker.sock:/var/run/docker.sock docker/compose:1.7.1

.PHONY: build deploy stop

all: build deploy

build:
	$(COMPOSE) -f docker-compose.yml --project-name elter_getit build

deploy:
	$(COMPOSE) -f docker-compose.yml up -d

stop:
	$(COMPOSE) -f docker-compose.yml stop
