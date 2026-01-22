IMAGE_NAME := ecrin-lab
CONTAINER_NAME := lab
REPO_DIR := $(shell pwd)
DOCKER_EXEC := docker exec $(CONTAINER_NAME) bash -c
REPO_URL := https://github.com/etnz/ecrin.git
REPO_DIR := /root/ecrin
BRANCH := master

.PHONY: clean build lab enter setup


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
		$(IMAGE_NAME)
	@echo "✅ Lab has started !"


enter:
	docker exec -it $(CONTAINER_NAME) bash

setup:
	@echo "Provisioning Ecrin..."
	
	@echo "🔑 Injecting Key ..."
	@docker cp age.key $(CONTAINER_NAME):/root/age.key
	@$(DOCKER_EXEC) "chmod 600 /root/age.key"
	
	@echo "🔑 Injecting Sops settings..."
	@docker cp .sops.yaml $(CONTAINER_NAME):/root/.sops.yaml
	
	@$(DOCKER_EXEC) "git clone -b $(BRANCH) $(REPO_URL) $(REPO_DIR)"
	
	@$(DOCKER_EXEC) "[ -d $(REPO_DIR) ]" || (echo "❌ FAIL: Directory $(REPO_DIR) missing!" && exit 1)
	@$(DOCKER_EXEC) "[ -d $(REPO_DIR)/.git ]" || (echo "❌ FAIL: .git folder missing! Clone failed." && exit 1)
	@$(DOCKER_EXEC) "[ -f $(REPO_DIR)/ecrin.service ]" || (echo "❌ FAIL: ecrin.service file missing! Repo seems empty." && exit 1)
	@echo "✅ Repo checks passed."

	@echo "Temp hack: use lab files instead of git prod files."
	@# this won't work for test that attempting to simulate a remote change.
	@docker cp ecrin.service $(CONTAINER_NAME):/root/ecrin/ecrin.service
	@docker cp docker-compose.yml $(CONTAINER_NAME):/root/ecrin/docker-compose.yml
	@docker cp secrets.enc.env $(CONTAINER_NAME):/root/ecrin/secrets.enc.env
	

	@echo "🔗 Linking Test Service..."
	@$(DOCKER_EXEC) "ln -sf $(REPO_DIR)/ecrin.service /etc/systemd/system/ecrin.service"
	@$(DOCKER_EXEC) "[ -f /etc/systemd/system/ecrin.service ]" || (echo "❌ FAIL: system/ecrin.service is missing! link failed." && exit 1)

	@echo "⚡ Starting Systemd Loop..."
	@$(DOCKER_EXEC) "systemctl daemon-reload"
	@$(DOCKER_EXEC) "systemctl enable --now ecrin.service"

	@echo "⏳ Waiting for service initialization (5s)..."
	@sleep 5
	
	@$(DOCKER_EXEC) "systemctl is-active ecrin.service >/dev/null" || (echo "❌ FAIL: Service is NOT active!" && exit 1)
	@echo "✅ Systemd Status: ACTIVE"
	
	@echo "📊 Last 10 log lines:"
	@$(DOCKER_EXEC) "journalctl -u ecrin.service -n 10 --no-pager"
	
	@echo "✅ Service seems healthy."
	@echo "✅ Setup Complete. Ecrin is active."

	@echo "🩺 Running Health Check..."
	@sleep 5
	
	@docker exec lab docker ps | grep ecrin-verifier || (echo "❌ Conteneur absent !" && exit 1)
	
	@echo "🔍 Testing Secret Injection..."
	@$(DOCKER_EXEC) "curl -s 'localhost:8080/?env=true' > /tmp/check_result \
		&& cat /tmp/check_result \
		&& grep -q 'SUPER_SECRET=world' /tmp/check_result" \
		|| (echo "\n❌ FAIL: line 'SUPER_SECRET=world' is missing !" && exit 1)
	
	@echo "✅ PASSED"
