#!/usr/bin/env python3
"""
ngrok URL Updater for n8n
Automatically fetches the ngrok tunnel URL and updates n8n webhook configuration
"""

import os
import json
import time
import logging
import requests
from datetime import datetime
from typing import Optional, Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/ngrok-updater.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class NgrokUpdater:
    def __init__(self):
        self.ngrok_api_url = os.getenv('NGROK_API_URL', 'http://ngrok:4040/api/tunnels')
        self.n8n_api_url = os.getenv('N8N_API_URL', 'http://n8n:5678/api/v1')
        self.update_interval = int(os.getenv('UPDATE_INTERVAL', '30'))
        self.webhook_file_path = os.getenv('WEBHOOK_FILE_PATH', '/tmp/webhook-url.txt')
        self.current_webhook_url = None
        
    def get_ngrok_tunnel_url(self) -> Optional[str]:
        """Fetch the current ngrok tunnel URL"""
        try:
            response = requests.get(self.ngrok_api_url, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            tunnels = data.get('tunnels', [])
            
            # Find the HTTP tunnel (not HTTPS for simplicity in development)
            for tunnel in tunnels:
                if tunnel.get('proto') == 'http':
                    public_url = tunnel.get('public_url')
                    if public_url:
                        logger.info(f"Found ngrok tunnel URL: {public_url}")
                        return public_url
                        
            # If no HTTP tunnel found, try HTTPS
            for tunnel in tunnels:
                if tunnel.get('proto') == 'https':
                    public_url = tunnel.get('public_url')
                    if public_url:
                        logger.info(f"Found ngrok tunnel URL (HTTPS): {public_url}")
                        return public_url
                        
            logger.warning("No active ngrok tunnels found")
            return None
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch ngrok tunnel URL: {e}")
            return None
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse ngrok API response: {e}")
            return None
            
    def update_webhook_file(self, webhook_url: str) -> bool:
        """Update the webhook URL file that n8n can read"""
        try:
            with open(self.webhook_file_path, 'w') as f:
                f.write(webhook_url)
            logger.info(f"Updated webhook file with URL: {webhook_url}")
            return True
        except Exception as e:
            logger.error(f"Failed to update webhook file: {e}")
            return False
            
    def check_n8n_health(self) -> bool:
        """Check if n8n is healthy and accessible"""
        try:
            response = requests.get(f"{self.n8n_api_url.replace('/api/v1', '')}/healthz", timeout=5)
            return response.status_code == 200
        except:
            return False
            
    def wait_for_services(self) -> None:
        """Wait for ngrok and n8n services to be ready"""
        logger.info("Waiting for services to be ready...")
        
        # Wait for ngrok
        ngrok_ready = False
        n8n_ready = False
        
        for attempt in range(60):  # Wait up to 5 minutes
            if not ngrok_ready:
                try:
                    requests.get(self.ngrok_api_url, timeout=2)
                    ngrok_ready = True
                    logger.info("ngrok API is ready")
                except:
                    pass
                    
            if not n8n_ready:
                if self.check_n8n_health():
                    n8n_ready = True
                    logger.info("n8n is ready")
                    
            if ngrok_ready and n8n_ready:
                logger.info("All services are ready!")
                return
                
            time.sleep(5)
            
        if not ngrok_ready:
            logger.error("ngrok service is not ready after 5 minutes")
        if not n8n_ready:
            logger.error("n8n service is not ready after 5 minutes")
            
    def run(self):
        """Main loop to monitor and update webhook URL"""
        logger.info("Starting ngrok URL updater...")
        
        # Wait for services to be ready
        self.wait_for_services()
        
        # Initial webhook URL fetch
        webhook_url = self.get_ngrok_tunnel_url()
        if webhook_url:
            self.current_webhook_url = webhook_url
            self.update_webhook_file(webhook_url)
            logger.info(f"Initial webhook URL set to: {webhook_url}")
        else:
            logger.warning("Could not get initial webhook URL")
            
        # Main monitoring loop
        while True:
            try:
                webhook_url = self.get_ngrok_tunnel_url()
                
                if webhook_url and webhook_url != self.current_webhook_url:
                    logger.info(f"Webhook URL changed from {self.current_webhook_url} to {webhook_url}")
                    self.current_webhook_url = webhook_url
                    
                    if self.update_webhook_file(webhook_url):
                        logger.info("Successfully updated webhook configuration")
                    else:
                        logger.error("Failed to update webhook configuration")
                        
                elif webhook_url:
                    logger.debug(f"Webhook URL unchanged: {webhook_url}")
                else:
                    logger.warning("No webhook URL available")
                    
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                
            time.sleep(self.update_interval)

if __name__ == "__main__":
    updater = NgrokUpdater()
    updater.run()
