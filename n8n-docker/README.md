# n8n Docker Compose Setup

This is a Docker Compose configuration for running n8n with PostgreSQL.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Configuration

1. Copy the example environment file to create your own configuration:

```bash
cp .env.example .env
```

2. Edit the `.env` file and modify the following configuration values:

- `N8N_ENCRYPTION_KEY`: Replace `your_secret_encryption_key_here` with a secure random string. This is used to encrypt credentials and should be kept secret.
- `GENERIC_TIMEZONE` and `TZ`: Set these to your local timezone (e.g., `America/New_York`, `Europe/Berlin`).
- Database passwords: You may want to change the PostgreSQL passwords for security.

## Starting n8n

To start n8n, navigate to the directory containing the `docker-compose.yml` file and run:

```bash
docker compose up -d
```

This will start n8n in detached mode. Once running, you can access n8n by opening: http://localhost:5678

## Stopping n8n

To stop n8n, run:

```bash
docker compose down
```

## Updating n8n

To update n8n to the latest version:

```bash
# Pull latest version
docker compose pull

# Stop and remove older version
docker compose down

# Start the container
docker compose up -d
```

## Data Persistence

The Docker Compose configuration creates two volumes to persist data:

- `n8n_data`: Stores n8n user data and encryption keys
- `postgres_data`: Stores the PostgreSQL database

## Additional Information

For more advanced configuration options, refer to the [n8n documentation](https://docs.n8n.io/hosting/installation/docker/).
