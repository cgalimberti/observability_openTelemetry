#!/bin/bash

# Script to stop the entire application stack
echo "Stopping the observability stack..."

# Detect docker compose command (docker compose vs docker-compose)
if docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose --version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "Error: Docker Compose is not installed"
    exit 1
fi

$DOCKER_COMPOSE down

echo "Stack stopped successfully!"
