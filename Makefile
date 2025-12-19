# --- AWS Configuration ---
REGION_ENV     := $(shell echo $$AWS_REGION)
REGION_CLI     := $(shell aws configure get region 2>/dev/null)
AWS_REGION     := $(if $(REGION_ENV),$(REGION_ENV),$(REGION_CLI))

AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null)

# --- Repository Configuration ---
REPO_NAME      := $(shell echo $$REPO_NAME)

# --- Strict Validation ---
ifeq ($(strip $(AWS_REGION)),)
$(error ERROR: AWS_REGION is not set. Export it with 'export AWS_REGION=your-region')
endif

ifeq ($(strip $(AWS_ACCOUNT_ID)),)
$(error ERROR: Could not retrieve AWS_ACCOUNT_ID. Check your session/token)
endif

ifeq ($(strip $(REPO_NAME)),)
$(error ERROR: REPO_NAME is not set. Export it with 'export REPO_NAME=dev-redis')
endif

# --- Image Metadata ---
IMAGE_NAME     := custom-redis-cluster
TAG            := latest
FULL_IMAGE_URI := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(REPO_NAME):$(TAG)

# --- Test Credentials ---
REDIS_PASS     := my-secret-password

.PHONY: build login push test clean info

info:
	@echo "Detected AWS Region:     $(AWS_REGION)"
	@echo "Detected AWS Account:    $(AWS_ACCOUNT_ID)"
	@echo "Detected Repo Name:      $(REPO_NAME)"
	@echo "Target ECR URI:          $(FULL_IMAGE_URI)"

build:
	docker build -t $(IMAGE_NAME) .

login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

push: build login
	docker tag $(IMAGE_NAME) $(FULL_IMAGE_URI)
	docker push $(FULL_IMAGE_URI)

test: build
	@echo "Starting Redis Cluster test container..."
	docker run -d --name redis-test-run \
		-e REDIS_PASSWORD=$(REDIS_PASS) \
		-p 6379:6379 \
		$(IMAGE_NAME)
	@echo "Waiting for Redis TLS and Cluster initialization..."
	@count=0; \
	until docker exec redis-test-run redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a $(REDIS_PASS) ping | grep -q "PONG"; do \
		if [ $$count -eq 15 ]; then echo "Timed out waiting for Redis"; $(MAKE) clean; exit 1; fi; \
		echo "Waiting for PONG..."; \
		sleep 2; \
		count=$$((count + 1)); \
	done
	@echo "Redis is UP. Checking Cluster Nodes:"
	docker exec redis-test-run redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a $(REDIS_PASS) cluster nodes
	@echo "Checking Cluster Info:"
	docker exec redis-test-run redis-cli --tls --cert /certs/redis.crt --key /certs/redis.key --cacert /certs/ca.crt -a $(REDIS_PASS) cluster info
	@$(MAKE) clean

clean:
	@docker rm -f redis-test-run 2>/dev/null || true
