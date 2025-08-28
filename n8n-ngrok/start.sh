#!/bin/bash

# Quick start script for n8n + ngrok
# Run this after setup.sh to start the services

set -e

echo "🚀 Starting n8n + ngrok services..."

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Please run ./setup.sh first${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Ask about Ollama
echo -e "${BLUE}🤖 Do you want to include Ollama (AI/LLM service)?${NC}"
read -p "This will use additional resources (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}📦 Starting services with Ollama...${NC}"
    docker compose --profile ollama up -d
else
    echo -e "${BLUE}📦 Starting core services...${NC}"
    docker compose up -d
fi

echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"

# Wait for services to be healthy
timeout=300  # 5 minutes
counter=0

while [ $counter -lt $timeout ]; do
    if docker compose ps --format json | jq -e '.[] | select(.Health == "healthy" or .Health == null)' > /dev/null 2>&1; then
        # Check if ngrok is providing a tunnel
        if curl -s http://localhost:4040/api/tunnels | jq -e '.tunnels | length > 0' > /dev/null 2>&1; then
            break
        fi
    fi
    
    sleep 2
    counter=$((counter + 2))
    
    if [ $((counter % 20)) -eq 0 ]; then
        echo -e "${BLUE}⏳ Still waiting... (${counter}s/${timeout}s)${NC}"
    fi
done

if [ $counter -ge $timeout ]; then
    echo -e "${YELLOW}⚠️  Services are taking longer than expected to start${NC}"
    echo -e "${BLUE}📊 Current status:${NC}"
    docker compose ps
    exit 1
fi

# Get the ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url // empty')

echo
echo -e "${GREEN}✅ Services are ready!${NC}"
echo
echo -e "${YELLOW}📋 Access Information:${NC}"
echo -e "${BLUE}🌐 n8n Interface:${NC} http://localhost:5678"
echo -e "${BLUE}📡 ngrok Dashboard:${NC} http://localhost:4040"

if [ -n "$NGROK_URL" ]; then
    echo -e "${BLUE}🔗 Public n8n URL:${NC} $NGROK_URL"
    echo -e "${GREEN}🎉 Your n8n instance is now accessible worldwide!${NC}"
else
    echo -e "${YELLOW}⚠️  ngrok URL not yet available. Check the ngrok dashboard.${NC}"
fi

echo
echo -e "${YELLOW}📊 Useful Commands:${NC}"
echo -e "${BLUE}# View logs:${NC} docker compose logs -f"
echo -e "${BLUE}# Stop services:${NC} docker compose down"
echo -e "${BLUE}# Restart services:${NC} docker compose restart"
echo
echo -e "${GREEN}🚀 Happy automating with n8n!${NC}"
