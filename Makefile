IMAGE_NAME = ecrin-lab
CONTAINER_NAME = lab
REPO_DIR = $(shell pwd)

.PHONY: clean build lab enter


clean:
	@echo "Cleaning Lab Container..."
	docker rm -f $(CONTAINER_NAME)

build:
	docker build -f Dockerfile.lab -t $(IMAGE_NAME) .

lab: clean build
	@echo "Running systemd Lab container..."
	docker run -d \
		--name $(CONTAINER_NAME) \
		--privileged \
		-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(REPO_DIR):/root/ecrin \
		$(IMAGE_NAME)
	@echo "✅ Lab has started !"


enter:
	docker exec -it $(CONTAINER_NAME) bash



