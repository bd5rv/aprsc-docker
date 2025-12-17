.PHONY: build run stop clean logs shell config-example test-multiarch push-multiarch inspect-multiarch

# Build image
build:
	docker build -t aprsc .

# Run container
run:
	docker-compose up -d

# Stop container
stop:
	docker-compose down

# View logs
logs:
	docker-compose logs -f

# Enter container shell
shell:
	docker-compose exec aprsc sh

# Extract example configuration file
config-example:
	@echo "Extracting example configuration file..."
	@if [ ! -f aprsc.conf ]; then \
		docker build -t aprsc . && \
		docker run --rm aprsc cat /etc/aprsc/aprsc.conf.example > aprsc.conf 2>/dev/null || \
		wget -O aprsc.conf https://raw.githubusercontent.com/hessu/aprsc/master/src/aprsc.conf; \
		echo "Configuration file saved to aprsc.conf, please edit before use"; \
	else \
		echo "aprsc.conf already exists, skipping"; \
	fi

# Clean up
clean:
	docker-compose down -v
	docker rmi aprsc 2>/dev/null || true

# Complete deployment workflow
deploy: config-example
	@echo "Please edit aprsc.conf file, then run 'make run' to start service"

# Multi-architecture targets

# Test multi-architecture build locally
test-multiarch:
	@echo "Testing multi-architecture build..."
	@if [ -z "$(PLATFORM)" ]; then \
		./test-multiarch-build.sh; \
	else \
		./test-multiarch-build.sh $(PLATFORM); \
	fi

# Push multi-architecture image to Docker Hub
push-multiarch:
	@echo "Building and pushing multi-architecture images to Docker Hub..."
	./push-to-dockerhub.sh

# Inspect multi-architecture manifest list on Docker Hub
inspect-multiarch:
	@echo "Inspecting multi-architecture manifest list..."
	docker buildx imagetools inspect bd5rv/aprsc:latest
