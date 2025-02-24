#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

curl -s https://file.winsnip.xyz/file/uploads/Logo-winsip.sh | bash
echo -e "${CYAN}Starting Docker and Grass desktop...${NC}"
sleep 2

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "-----------------------------------------------------"
    case $level in
        "INFO") echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS] ${timestamp} - ${message}${NC}" ;;
        "ERROR") echo -e "${RED}[ERROR] ${timestamp} - ${message}${NC}" ;;
    esac
    echo -e "-----------------------------------------------------\n"
}

log "INFO" "Memperbarui daftar paket dan menginstal paket dasar..."
apt update
log "SUCCESS" "Daftar paket diperbarui."

apt upgrade -y
log "SUCCESS" "Paket dasar berhasil diinstal."

log "INFO" "Mengunduh arsip grass.rar..."
curl -L -o "$HOME/grass.rar" https://files.getgrass.io/file/grass-extension-upgrades/ubuntu-22.04/Grass_5.1.0_amd64.deb
log "SUCCESS" "Arsip grass.rar berhasil diunduh."

log "INFO" "Membuat direktori untuk grass dan mengekstrak arsip..."
mkdir -p $HOME/grass && cd $HOME/grass

if ! command -v unrar &> /dev/null; then
    log "INFO" "Unrar belum terinstal. Menginstal unrar..."
    apt install unrar -y
    log "SUCCESS" "Unrar berhasil diinstal."
fi

unrar x "$HOME/grass.rar"
log "SUCCESS" "Arsip grass.rar berhasil diekstrak."

rm "$HOME/grass.rar"
log "INFO" "Menghapus arsip grass.rar setelah ekstraksi."

read -p "Masukkan port untuk web listening (default 7700): " WEB_LISTENING_PORT
WEB_LISTENING_PORT=${WEB_LISTENING_PORT:-7700}

log "INFO" "Membangun kontainer Docker untuk Grass..."
docker build -t winsnip/grass:latest . && \
docker run -d \
   --restart unless-stopped \
   --name grass \
   --network host \
   -v "$HOME/appdata/grass:/config" \
   -e USER_ID="$(id -u)" \
   -e GROUP_ID="$(id -g)" \
   -e WEB_LISTENING_PORT="$WEB_LISTENING_PORT" \
   winsnip/grass:latest
log "SUCCESS" "Kontainer Grass berjalan dengan nama 'grass'."

log "INFO" "Mengonfigurasi firewall..."
sudo ufw allow "$WEB_LISTENING_PORT"/tcp
log "SUCCESS" "Firewall dikonfigurasi untuk mengizinkan akses ke port $WEB_LISTENING_PORT."

IP_ADDRESS=$(hostname -I | awk '{print $1}')
URL="https://$IP_ADDRESS:$WEB_LISTENING_PORT/"
log "SUCCESS" "Setup selesai! Browser dibuka di $URL."
