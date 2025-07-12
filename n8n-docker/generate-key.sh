#!/bin/bash

# Generate a random string for encryption key
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Create .env file from example if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file from template"
fi

# Replace the placeholder with the generated key
sed -i.bak "s/your_secret_encryption_key_here/$ENCRYPTION_KEY/" .env
rm -f .env.bak

echo "N8N_ENCRYPTION_KEY has been set to a secure random value in your .env file"
echo "You can now start n8n with 'docker compose up -d'"
