#!/bin/bash

set -euxo pipefail

# Actualizar sistema
dnf update -y

# Instalar Docker, Git y OpenSSL
dnf install -y \
    docker \
    git \
    openssl

# Docker
systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

# SSM
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Directorios
mkdir -p /opt/portfolio/nginx
mkdir -p /opt/portfolio/certs


# Docker Compose install
mkdir -p /usr/local/lib/docker/cli-plugins

curl -SL \
    https://github.com/docker/compose/releases/download/v5.1.4/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

docker compose version

mkdir -p /opt/portfolio/nginx
mkdir -p /opt/portfolio/certs


# Certificado temporal autofirmado
openssl req \
    -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout /opt/portfolio/certs/privkey.pem \
    -out /opt/portfolio/certs/fullchain.pem \
    -subj "/CN=portfolio"

# Configuración Nginx
cat > /opt/portfolio/nginx/nginx.conf <<'EOF'
server {
    listen 443 ssl;

    server_name _;

    ssl_certificate     /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    location / {
        proxy_pass http://bff:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Docker Compose
cat > /opt/portfolio/compose.yaml <<'EOF'
services:

  nginx:
    image: nginx:alpine
    restart: unless-stopped

    ports:
      - "443:443"

    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/nginx/certs:ro

    networks:
      - edge

    depends_on:
      - bff


  bff:
    image: hotdoctor/portfolio-backend:latest
    restart: unless-stopped

    environment:
      LANGUAGE_SERVICE_URL: http://language-service:8081

    networks:
      - edge
      - microservices


  language-service:
    image: hotdoctor/portfolio-microservices-language_service:latest
    restart: unless-stopped

    networks:
      - microservices


networks:

  edge:
    driver: bridge

  microservices:
    driver: bridge
EOF

chown -R ec2-user:ec2-user /opt/portfolio

cd /opt/portfolio

docker compose pull
docker compose up -d