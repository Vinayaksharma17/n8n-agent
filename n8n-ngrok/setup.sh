#!/bin/bash

# n8n + ngrok Automated Setup Script
# This script generates required keys and sets up the environment

set -e

echo "🚀 Setting up n8n with ngrok automation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to generate a secure encryption key
generate_encryption_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 32
    elif command -v python3 &> /dev/null; then
        python3 -c "import secrets; print(secrets.token_hex(32))"
    else
        # Fallback to date-based random
        echo "$(date +%s)$(shuf -i 1000-9999 -n 1)" | sha256sum | cut -d' ' -f1
    fi
}

# Function to generate a secure password
generate_password() {
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-16
    else
        echo "secure_pass_$(date +%s)"
    fi
}

# Check if .env exists and ask if user wants to regenerate
if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file already exists.${NC}"
    read -p "Do you want to regenerate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  Using existing .env file${NC}"
        exit 0
    fi
fi

# Generate encryption key and password
echo -e "${BLUE}🔐 Generating encryption key and password...${NC}"
ENCRYPTION_KEY=$(generate_encryption_key)
DB_PASSWORD=$(generate_password)

# Get ngrok authtoken from user
echo -e "${YELLOW}📡 ngrok Configuration${NC}"
echo "To get your ngrok authtoken:"
echo "1. Sign up at https://ngrok.com/"
echo "2. Go to https://dashboard.ngrok.com/get-started/your-authtoken"
echo "3. Copy your authtoken"
echo

read -p "Enter your ngrok authtoken: " NGROK_AUTHTOKEN

if [ -z "$NGROK_AUTHTOKEN" ]; then
    echo -e "${RED}❌ ngrok authtoken is required!${NC}"
    exit 1
fi

# Ask for region preference
echo -e "${BLUE}🌍 Select ngrok region:${NC}"
echo "1. us (United States - default)"
echo "2. eu (Europe)"
echo "3. ap (Asia Pacific)"
echo "4. au (Australia)"
echo "5. sa (South America)"
echo "6. jp (Japan)"
echo "7. in (India)"

read -p "Enter your choice (1-7, default: 1): " REGION_CHOICE

case $REGION_CHOICE in
    2) NGROK_REGION="eu" ;;
    3) NGROK_REGION="ap" ;;
    4) NGROK_REGION="au" ;;
    5) NGROK_REGION="sa" ;;
    6) NGROK_REGION="jp" ;;
    7) NGROK_REGION="in" ;;
    *) NGROK_REGION="us" ;;
esac

# Create .env file
echo -e "${BLUE}📝 Creating .env file...${NC}"
cat > .env << EOF
# n8n Configuration
N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}
N8N_PORT=5678
TIMEZONE=UTC

# PostgreSQL Configuration
POSTGRES_USER=n8n
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=n8n

# ngrok Configuration
NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}
NGROK_REGION=${NGROK_REGION}

# Optional: Ollama Configuration
OLLAMA_PORT=11434

# Updater Service Configuration
UPDATE_INTERVAL=30

# Initial webhook URL (will be automatically updated)
N8N_WEBHOOK_URL=http://localhost:5678
EOF

# Create necessary directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p logs

# Create initial webhook URL file
touch webhook-url.txt

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo -e "${BLUE}🚫 Creating .gitignore...${NC}"
    cat > .gitignore << EOF
.env
webhook-url.txt
logs/
*.log
EOF
fi

echo -e "${GREEN}✅ Setup complete!${NC}"
echo
echo -e "${YELLOW}📋 Quick Start Commands:${NC}"
echo -e "${BLUE}# Start all services:${NC}"
echo "docker compose up -d"
echo
echo -e "${BLUE}# Start with Ollama (AI features):${NC}"
echo "docker compose --profile ollama up -d"
echo
echo -e "${BLUE}# View logs:${NC}"
echo "docker compose logs -f"
echo
echo -e "${BLUE}# Check ngrok status:${NC}"
echo "open http://localhost:4040"
echo
echo -e "${BLUE}# Access n8n (after startup):${NC}"
echo "open http://localhost:5678"
echo
echo -e "${YELLOW}🔗 The ngrok URL will be automatically detected and used for webhooks!${NC}"
echo -e "${GREEN}🎉 Your n8n instance will be accessible via the ngrok tunnel once started.${NC}"
