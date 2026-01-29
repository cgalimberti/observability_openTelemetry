#!/bin/bash

# Script to run the entire application stack
set -e

echo "Building and starting the observability stack..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Detect docker compose command (docker compose vs docker-compose)
if docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose --version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "Error: Docker Compose is not installed"
    echo "Install it from: https://docs.docker.com/compose/install/"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)
fi
if [ -f .env.local ]; then
    export $(cat .env.local | grep -v '^#' | grep -v '^$' | xargs)
fi

# Start all services
$DOCKER_COMPOSE up -d

echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "=========================================="
echo "Services are now running!"
echo "=========================================="
echo ""
echo "Service A (Input Handler):  http://localhost:8080"
echo "Service B (Orchestration):  http://localhost:8081"
echo "Zipkin (Tracing):           http://localhost:9411"
echo ""
echo "Health checks:"
echo "  Service A: curl http://localhost:8080/health"
echo "  Service B: curl http://localhost:8081/health"
echo ""
echo "Test the API:"
echo "  curl -X POST http://localhost:8080/cep -H 'Content-Type: application/json' -d '{\"cep\":\"01310100\"}'"
echo ""
echo "View traces at: http://localhost:9411"
echo ""
echo "Stop services with: ./stop.sh"
echo ""