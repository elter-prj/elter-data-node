DOCKER   := docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR)
COMPOSE  := $(DOCKER) -v /var/run/docker.sock:/var/run/docker.sock docker/compose:1.7.1

.PHONY: deploy stop


deploy:
	# Bring up the containers
	$(COMPOSE) -f docker-compose.yml build
	$(COMPOSE) -f docker-compose.yml up -d
                        
stop:
	$(COMPOSE) -f docker-compose.yml stop

