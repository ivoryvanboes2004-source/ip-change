#!/bin/bash
# ================================================
#  Change Static IP - Ubuntu (Netplan)
#  github.com/JOUW-GEBRUIKERSNAAM/change-ip-ubuntu
# ================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  _____ _____     _____ _                            "
echo " |_   _|  __ \   / ____| |                           "
echo "   | | | |__) | | |    | |__   __ _ _ __   __ _  ___ "
echo "   | | |  ___/  | |    | '_ \ / _\` | '_ \ / _\` |/ _ \\"
echo "  _| |_| |      | |____| | | | (_| | | | | (_| |  __/"
echo " |_____|_|       \_____|_| |_|\__,_|_| |_|\__, |\___|"
echo "                                            __/ |     "
echo "                                           |___/      "
echo -e "${NC}"

# Root check
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}[ERROR] Run as root: sudo ./ip-change.sh${NC}"
  exit 1
fi

# ── Auto-detecteer huidige netwerkinstellingen ───

# Detecteer actieve interface
DETECTED_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)

# Detecteer huidig IP en subnet
DETECTED_IP_CIDR=$(ip addr show "$DETECTED_INTERFACE" 2>/dev/null | grep 'inet ' | awk '{print $2}' | head -1)
DETECTED_IP=$(echo "$DETECTED_IP_CIDR" | cut -d'/' -f1)
DETECTED_SUBNET=$(echo "$DETECTED_IP_CIDR" | cut -d'/' -f2)

# Detecteer gateway
DETECTED_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)

# Detecteer DNS
DETECTED_DNS=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | head -2 | tr '\n' ' ' | sed 's/ $//')
DETECTED_DNS1=$(echo "$DETECTED_DNS" | awk '{print $1}')
DETECTED_DNS2=$(echo "$DETECTED_DNS" | awk '{print $2}')
[[ -z "$DETECTED_DNS1" ]] && DETECTED_DNS1="8.8.8.8"
[[ -z "$DETECTED_DNS2" ]] && DETECTED_DNS2="1.1.1.1"

# ── Toon huidige instellingen ────────────────────
echo -e "${CYAN}── Huidige instellingen ─────────────────────────${NC}"
echo -e "  Interface : ${YELLOW}$DETECTED_INTERFACE${NC}"
echo -e "  IP adres  : ${YELLOW}$DETECTED_IP${NC}"
echo -e "  Subnet    : ${YELLOW}$DETECTED_SUBNET${NC}"
echo -e "  Gateway   : ${YELLOW}$DETECTED_GATEWAY${NC}"
echo -e "  DNS 1     : ${YELLOW}$DETECTED_DNS1${NC}"
echo -e "  DNS 2     : ${YELLOW}$DETECTED_DNS2${NC}"
echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
echo ""
echo -e "${BOLD}Druk op Enter om de huidige waarde te behouden.${NC}"
echo ""

# ── Gebruiker laat nieuwe waarden invullen ───────
read -p "Interface  [$DETECTED_INTERFACE]: " INPUT_INTERFACE
INTERFACE=${INPUT_INTERFACE:-$DETECTED_INTERFACE}

read -p "IP adres   [$DETECTED_IP]: " INPUT_IP
IP_ADDRESS=${INPUT_IP:-$DETECTED_IP}

read -p "Subnet     [$DETECTED_SUBNET]: " INPUT_SUBNET
SUBNET=${INPUT_SUBNET:-$DETECTED_SUBNET}

read -p "Gateway    [$DETECTED_GATEWAY]: " INPUT_GATEWAY
GATEWAY=${INPUT_GATEWAY:-$DETECTED_GATEWAY}

read -p "DNS 1      [$DETECTED_DNS1]: " INPUT_DNS1
DNS1=${INPUT_DNS1:-$DETECTED_DNS1}

read -p "DNS 2      [$DETECTED_DNS2]: " INPUT_DNS2
DNS2=${INPUT_DNS2:-$DETECTED_DNS2}

# ── Overzicht nieuwe instellingen ───────────────
echo ""
echo -e "${CYAN}── Nieuwe instellingen ──────────────────────────${NC}"
echo -e "  Interface : ${GREEN}$INTERFACE${NC}"
echo -e "  IP adres  : ${GREEN}$IP_ADDRESS/$SUBNET${NC}"
echo -e "  Gateway   : ${GREEN}$GATEWAY${NC}"
echo -e "  DNS       : ${GREEN}$DNS1, $DNS2${NC}"
echo -e "${CYAN}─────────────────────────────────────────────────${NC}"
echo ""

read -p "Toepassen? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo -e "${YELLOW}Geannuleerd.${NC}"
  exit 0
fi

# ── Netplan bestand zoeken ───────────────────────
NETPLAN_FILE=$(find /etc/netplan/ -name "*.yaml" | head -1)
if [[ -z "$NETPLAN_FILE" ]]; then
  echo -e "${RED}[ERROR] Geen netplan config gevonden in /etc/netplan/${NC}"
  exit 1
fi

# Backup maken
BACKUP="${NETPLAN_FILE}.bak.$(date +%Y%m%d%H%M%S)"
cp "$NETPLAN_FILE" "$BACKUP"
echo -e "${GREEN}[OK] Backup: $BACKUP${NC}"

# Nieuwe config schrijven
cat > "$NETPLAN_FILE" <<EOF
network:
  version: 2
  ethernets:
    ${INTERFACE}:
      dhcp4: no
      addresses:
        - ${IP_ADDRESS}/${SUBNET}
      routes:
        - to: default
          via: ${GATEWAY}
      nameservers:
        addresses: [${DNS1}, ${DNS2}]
EOF

echo -e "${GREEN}[OK] Config geschreven${NC}"
echo -e "${YELLOW}[INFO] Netplan wordt toegepast...${NC}"

netplan apply

if [[ $? -eq 0 ]]; then
  echo ""
  echo -e "${GREEN}✓ IP succesvol gewijzigd naar $IP_ADDRESS/$SUBNET${NC}"
  echo ""
  ip addr show "$INTERFACE"
else
  echo -e "${RED}[ERROR] netplan apply mislukt. Backup terugzetten...${NC}"
  cp "$BACKUP" "$NETPLAN_FILE"
  netplan apply
  echo -e "${YELLOW}[INFO] Originele config hersteld${NC}"
  exit 1
fi
