#!/bin/bash

set -euxo pipefail

DOMAIN="api-portfolio.zapto.org"
BASE_DIR="/opt/portfolio"

dnf update -y

dnf install -y \
    docker \
    git \
    openssl

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

mkdir -p /usr/local/lib/docker/cli-plugins

curl -fSL \
    https://github.com/docker/compose/releases/download/v5.1.4/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

docker compose version

mkdir -p "$BASE_DIR/nginx"
mkdir -p "$BASE_DIR/certbot/www/.well-known/acme-challenge"
mkdir -p "$BASE_DIR/certbot/conf"

cat > "$BASE_DIR/nginx/nginx.conf" <<'EOF'
server {
    listen 80;

    server_name api-portfolio.zapto.org;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://bff:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

cat > "$BASE_DIR/compose.yaml" <<'EOF'
services:

  nginx:
    image: nginx:alpine
    restart: unless-stopped

    ports:
      - "80:80"
      - "443:443"

    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certbot/www:/var/www/certbot:ro
      - ./certbot/conf:/etc/letsencrypt:ro

    networks:
      - edge

    depends_on:
      - bff

  certbot:
    image: certbot/certbot:latest

    profiles:
      - certbot

    volumes:
      - ./certbot/www:/var/www/certbot
      - ./certbot/conf:/etc/letsencrypt

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

chown -R ec2-user:ec2-user "$BASE_DIR"

cd "$BASE_DIR"

docker compose pull nginx bff language-service certbot

docker compose up -d nginx bff language-service

sleep 5

docker compose exec -T nginx nginx -t

echo "ok" > "$BASE_DIR/certbot/www/.well-known/acme-challenge/test"

curl -fsS \
    http://127.0.0.1/.well-known/acme-challenge/test

rm -f "$BASE_DIR/certbot/www/.well-known/acme-challenge/test"

if [ ! -f "$BASE_DIR/certbot/conf/live/$DOMAIN/fullchain.pem" ]; then

    docker compose run --rm certbot \
        certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --domain "$DOMAIN" \
        --agree-tos \
        --non-interactive \
        --register-unsafely-without-email

fi

test -f "$BASE_DIR/certbot/conf/live/$DOMAIN/fullchain.pem"
test -f "$BASE_DIR/certbot/conf/live/$DOMAIN/privkey.pem"

cat > "$BASE_DIR/nginx/nginx.conf" <<'EOF'
server {
    listen 80;

    server_name api-portfolio.zapto.org;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;

    server_name api-portfolio.zapto.org;

    ssl_certificate /etc/letsencrypt/live/api-portfolio.zapto.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api-portfolio.zapto.org/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://bff:8080;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

docker compose exec -T nginx nginx -t

docker compose exec -T nginx nginx -s reload

sleep 2

curl -vk \
    --resolve "$DOMAIN:443:127.0.0.1" \
    "https://$DOMAIN/"

cat > /etc/systemd/system/portfolio-certbot-renew.service <<'EOF'
[Unit]
Description=Renew Let's Encrypt certificate for portfolio
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/opt/portfolio
ExecStart=/usr/bin/docker compose run --rm certbot renew --quiet
ExecStartPost=/usr/bin/docker compose exec -T nginx nginx -t
ExecStartPost=/usr/bin/docker compose exec -T nginx nginx -s reload
EOF

cat > /etc/systemd/system/portfolio-certbot-renew.timer <<'EOF'
[Unit]
Description=Check Let's Encrypt certificate renewal

[Timer]
OnCalendar=*-*-* 03:00:00
OnCalendar=*-*-* 15:00:00
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload

systemctl enable --now portfolio-certbot-renew.timer

docker compose ps

systemctl status portfolio-certbot-renew.timer --no-pager