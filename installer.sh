#!/bin/bash

clear

RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
NC='\033[0m'

echo -e "${CYN}"
cat << "EOF"
██████╗ ██╗██╗  ██╗███████╗██╗  ██╗ ██████╗ ███████╗████████╗
██╔══██╗██║╚██╗██╔╝██╔════╝██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
██████╔╝██║ ╚███╔╝ █████╗  ███████║██║   ██║█████╗     ██║   
██╔═══╝ ██║ ██╔██╗ ██╔══╝  ██╔══██║██║   ██║██╔══╝     ██║   
██║     ██║██╔╝ ██╗███████╗██║  ██║╚██████╔╝██║        ██║   
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝        ╚═╝   
EOF
echo -e "${NC}"

echo -e "${YEL}🔥 PIXELHOST / PRIMEHOST INSTALLER${NC}"
echo -e "${GRN}=====================================${NC}"

echo -e "[1] Install Panel"
echo -e "[2] Install Wings"
echo -e "[3] Install Panel + Wings"
echo -e "[0] Exit"

read -p "Select option: " opt

install_docker() {
    echo -e "${CYN}📦 Installing Docker...${NC}"
    apt update -y
    apt install docker.io docker-compose -y
    systemctl enable docker
    systemctl start docker
}

install_panel() {
    echo -e "${GRN}✅ Pterodactyl PANEL o'rnatilmoqda...${NC}"

    install_docker

    mkdir -p /srv/pterodactyl/panel
    cd /srv/pterodactyl/panel || exit

    read -p "🌐 Domain (example.com): " domain
    read -p "📧 Admin Email: " email

    cat <<EOF > docker-compose.yml
version: '3.8'

services:
  database:
    image: mariadb:10.5
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: "rootpass"
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"
      MYSQL_PASSWORD: "panelpass"
    volumes:
      - "./data/db:/var/lib/mysql"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - "80:80"
    environment:
      APP_URL: "http://$domain"
      APP_ENV: "production"
      APP_SERVICE_AUTHOR: "$email"
      DB_HOST: "database"
      DB_PASSWORD: "panelpass"
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_DRIVER: "redis"
      REDIS_HOST: "cache"
    depends_on:
      - database
      - cache
EOF

    docker-compose up -d

    echo -e "${GRN}✅ PANEL INSTALL BO'LDI${NC}"
}

install_wings() {
    echo -e "${GRN}✅ WINGS o'rnatilmoqda...${NC}"

    install_docker

    mkdir -p /etc/pterodactyl
    cd /etc/pterodactyl || exit

    read -p "🔑 Wings config token (Paneldan): " token
    read -p "🌍 Panel URL: " panelurl

    cat <<EOF > config.yml
debug: false
panel_url: "$panelurl"
token: "$token"
allowed_mounts: []
remote: "$panelurl"
EOF

    cat <<EOF > docker-compose.yml
version: '3.8'

services:
  wings:
    image: ghcr.io/pterodactyl/wings:v1.6.1
    restart: always
    ports:
      - "8080:8080"
      - "2022:2022"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/pterodactyl:/etc/pterodactyl
      - /var/lib/pterodactyl:/var/lib/pterodactyl
EOF

    docker-compose up -d

    echo -e "${GRN}✅ WINGS INSTALL BO'LDI${NC}"
}

case $opt in
1)
    install_panel
    ;;
2)
    install_wings
    ;;
3)
    install_panel
    install_wings
    ;;
0)
    exit
    ;;
*)
    echo "Invalid option"
    ;;
esac
