#!/bin/bash

# Health check script for n8n + ngrok setup
# Verifies all services are running correctly

set -e

echo "🏥 n8n + ngrok Health Check"
echo "=========================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check service health
check_service() {
    local service=$1
    local url=$2
    local description=$3
    
    echo -n "🔍 Checking $description... "
    
    if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Healthy${NC}"
        return 0
    else
        echo -e "${RED}❌ Unhealthy${NC}"
        return 1
    fi
}

# Function to check ngrok tunnels
check_ngrok_tunnels() {
    echo -n "🔍 Checking ngrok tunnels... "
    
    local tunnels=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels | length' 2>/dev/null)
    
    if [ "$tunnels" = "null" ] || [ -z "$tunnels" ]; then
        echo -e "${RED}❌ No tunnels found${NC}"
        return 1
    elif [ "$tunnels" -gt 0 ]; then
        echo -e "${GREEN}✅ $tunnels tunnel(s) active${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  No active tunnels${NC}"
        return 1
    fi
}

# Function to display ngrok tunnel info
show_tunnel_info() {
    echo -e "\n${BLUE}📡 ngrok Tunnel Information:${NC}"
    
    local tunnel_info=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[] | "\(.proto)://\(.config.addr) -> \(.public_url)"' 2>/dev/null)
    
    if [ -n "$tunnel_info" ]; then
        echo "$tunnel_info"
    else
        echo "No tunnel information available"
    fi
}

# Function to check webhook URL file
check_webhook_file() {
    echo -n "🔍 Checking webhook URL file... "
    
    if [ -f "webhook-url.txt" ]; then
        local url=$(cat webhook-url.txt 2>/dev/null)
        if [ -n "$url" ]; then
            echo -e "${GREEN}✅ URL: $url${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  File empty${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ File not found${NC}"
        return 1
    fi
}

# Main health checks
echo -e "\n${BLUE}🏥 Service Health Checks${NC}"
echo "========================"

health_issues=0

# Check Docker services
echo -e "\n${YELLOW}Docker Services:${NC}"
if ! check_service "postgres" "http://localhost:5432" "PostgreSQL" 2>/dev/null; then
    echo -n "🔍 Checking PostgreSQL... "
    if docker compose ps postgres | grep -q "healthy"; then
        echo -e "${GREEN}✅ Healthy${NC}"
    else
        echo -e "${RED}❌ Unhealthy${NC}"
        ((health_issues++))
    fi
fi

if ! check_service "n8n" "http://localhost:5678/healthz" "n8n"; then
    ((health_issues++))
fi

if ! check_service "ngrok" "http://localhost:4040/api/tunnels" "ngrok API"; then
    ((health_issues++))
fi

# Check ngrok tunnels
echo -e "\n${YELLOW}ngrok Configuration:${NC}"
if ! check_ngrok_tunnels; then
    ((health_issues++))
fi

# Check webhook file
echo -e "\n${YELLOW}Webhook Configuration:${NC}"
if ! check_webhook_file; then
    ((health_issues++))
fi

# Show tunnel information
show_tunnel_info

# Check updater logs
echo -e "\n${BLUE}📝 Recent ngrok-updater Activity:${NC}"
if [ -f "logs/ngrok-updater.log" ]; then
    tail -n 5 logs/ngrok-updater.log 2>/dev/null || echo "No recent log entries"
else
    echo "Log file not found"
fi

# Docker compose status
echo -e "\n${BLUE}📊 Docker Compose Status:${NC}"
docker compose ps

# Summary
echo -e "\n${BLUE}📋 Health Summary${NC}"
echo "================="

if [ $health_issues -eq 0 ]; then
    echo -e "${GREEN}🎉 All systems are healthy!${NC}"
    echo -e "${GREEN}✅ n8n is ready for workflows${NC}"
    echo -e "${GREEN}✅ Webhooks are configured automatically${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Found $health_issues issue(s)${NC}"
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "   • Check service logs: docker compose logs -f [service-name]"
    echo "   • Restart services: docker compose restart"
    echo "   • Reset environment: docker compose down -v && docker compose up -d"
    exit 1
fi
