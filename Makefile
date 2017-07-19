DOCKER   := docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR)
DOCKER_BUILD := docker build
COMPOSE  := $(DOCKER) -v /var/run/docker.sock:/var/run/docker.sock docker/compose:1.14.0

.PHONY: build deploy stop stop-clear

# The building of the ceh-sos:1.0.0 needs to happen outside of the Docker compose
# file, as it is not a service we wish to deploy, it is simply to inherit from.
build:
	$(DOCKER_BUILD) sos-node/base-image/. --tag ceh-sos:1.0.0
	$(COMPOSE) -f docker-compose.yml build

deploy:
	$(COMPOSE) -f docker-compose.yml up -d

stop:
	$(COMPOSE) -f docker-compose.yml stop

stop-clear:
	$(COMPOSE) down -v
